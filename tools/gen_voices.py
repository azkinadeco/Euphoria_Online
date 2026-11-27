"""Generate all character voice lines (Heroes, NPCs, Enemies) via Voice Lab (http://localhost:3000).
Priority order:
  1. gemini-tts (Gemini 2.5 Flash/Pro TTS)
  2. freetts-api (FreeTTS Neural API, with automatic freetts.org watermark trimmer)
  3. voicevox (Unlimited local VOICEVOX engine with 100% female Anime JP speaker IDs)

Usage:
  python3 tools/gen_voices.py [--group heroes|npcs|enemies|all] [--force] [--reset-provider gemini-tts] [char_id ...]
"""
import array
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(ROOT, "audio", "voice")
VL_PATH = os.path.join(ROOT, "data", "voice_lines.json")
PROGRESS_PATH = os.path.join(ROOT, "data", "voice_generation_report.json")
VOICELAB_BASE = os.environ.get("VOICELAB_URL", "http://localhost:3000")
TARGET_SR = 22050

os.makedirs(OUT_DIR, exist_ok=True)

HERO_ORDER = [
    "shina", "xylia", "micca", "cthollia", "valeria", "eropatra", "furu", "glytta",
    "hyeonxa", "scylla", "lumeira", "gemora", "fidelia", "lucidria", "eurnipha", "rumi",
    "mora", "abadonia", "aqua", "atalanta", "kali", "zennyo", "rubby", "schylua",
    "vexira", "siv", "sven", "angela", "kara", "mei", "ninger", "spimei",
    "luby", "gala", "morana", "seraph", "tamo", "aura", "fuji", "kyra",
    "sharas", "toka", "tora", "tsundae", "vila", "yumi"
]

NPC_ORDER = ["shop1", "shop2", "hairly", "grafity"]

ENEMY_ORDER = [
    "amatera", "anthis", "cleara", "code_zero", "cow_girl", "eroghost", "evy_blood_sage",
    "ex_nymph", "graeae", "gumi_wolf", "hairly", "kurenai", "lamia", "lizamorph",
    "lolth", "nagini", "nox", "octavia", "octra", "rin", "roza", "scomantis",
    "selene", "serpentia", "skelinch", "slarkoi", "slime", "svormentis", "veyr_nok",
    "voodoo", "xaniyus", "ygg_naar", "ymir"
]

NPC_CATS = {"greet", "tap", "thanks", "poor", "tap_head", "tap_body", "tap_legs", "idle", "browse", "bye"}
ENEMY_HAIRLY_CATS = {"pet_0", "pet_1", "pet_2", "bond", "pet_4", "skill", "hurt", "ko"}

# Compensate for negative pitchOffset in Voice Lab's voices-data.ts so FreeTTS/Edge Neural
# NEVER shifts female voices down into a male register.
VOICE_PITCH_COMPENSATION = {
    "anime-reina-dewasa": 34,     # voices-data.ts has -30 -> effective +4Hz+
    "anime-lilith-menggoda": 25,  # voices-data.ts has -20 -> effective +5Hz+
    "anime-rika-marah": 23,       # voices-data.ts has -18 -> effective +5Hz+
    "anime-rei-sedih": 10,        # voices-data.ts has -4  -> effective +6Hz+
    "anime-akane-kasar": 3,       # voices-data.ts has +5  -> effective +8Hz+
    "anime-yui-lembut": 2,        # voices-data.ts has +8  -> effective +10Hz+
    "anime-hina-ceria": 0,        # voices-data.ts has +15 -> effective +15Hz+
    "anime-momo-imut": 0,         # voices-data.ts has +25 -> effective +25Hz+
}

# VOICEVOX speakers where Voice Lab's getSpeakerAcousticProfile lowered basePitch;
# we restore their natural feminine pitch factor during WAV post-processing.
VV_PITCH_RESTORE = {
    4: 1.038,
    5: 1.038,
    14: 1.018,
    17: 1.045,
    20: 1.045,
    22: 1.018,
    29: 1.045,
    36: 1.018,
}

# 100% Female Anime JP Voice Lab model + 100% Female VOICEVOX speaker IDs (zero male speakers!)
CHARACTER_VOICE_MAP = {
    # --- 46 HEROES (100% Female Anime JP) ---
    "shina":    {"voiceId": "anime-akane-kasar",     "vv": 6,  "speed": 1.04, "pitch": 2},
    "xylia":    {"voiceId": "anime-momo-imut",       "vv": 1,  "speed": 1.06, "pitch": 4},  # Imut (Zundamon Manis)
    "micca":    {"voiceId": "anime-momo-imut",       "vv": 43, "speed": 1.08, "pitch": 4},
    "cthollia": {"voiceId": "anime-yui-lembut",      "vv": 10, "speed": 0.96, "pitch": 2},
    "valeria":  {"voiceId": "anime-hina-ceria",      "vv": 8,  "speed": 1.06, "pitch": 3},  # Ceria (Kasukabe Tsumugi)
    "eropatra": {"voiceId": "anime-reina-dewasa",    "vv": 16, "speed": 0.95, "pitch": 2},  # Dewasa (Kyushu Sora Dewasa)
    "furu":     {"voiceId": "anime-yui-lembut",      "vv": 10, "speed": 0.96, "pitch": 2},
    "glytta":   {"voiceId": "anime-rika-marah",      "vv": 78, "speed": 1.05, "pitch": 2},  # Marah (Mochiko-san Marah)
    "hyeonxa":  {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},  # Menggoda (Mochiko-san Sexy)
    "scylla":   {"voiceId": "anime-rei-sedih",       "vv": 74, "speed": 0.94, "pitch": 2},
    "lumeira":  {"voiceId": "anime-yui-lembut",      "vv": 46, "speed": 0.94, "pitch": 4},
    "gemora":   {"voiceId": "anime-rei-sedih",       "vv": 47, "speed": 0.98, "pitch": 2},
    "fidelia":  {"voiceId": "anime-yui-lembut",      "vv": 2,  "speed": 1.00, "pitch": 2},
    "lucidria": {"voiceId": "anime-yui-lembut",      "vv": 10, "speed": 0.95, "pitch": 3},  # Suara Lembut (Amehare Hau)
    "eurnipha": {"voiceId": "anime-lilith-menggoda", "vv": 15, "speed": 0.94, "pitch": 2},
    "rumi":     {"voiceId": "anime-reina-dewasa",    "vv": 80, "speed": 0.96, "pitch": 2},  # Dewasa (Mochiko-san Dewasa)
    "mora":     {"voiceId": "anime-yui-lembut",      "vv": 0,  "speed": 0.95, "pitch": 2},
    "abadonia": {"voiceId": "anime-reina-dewasa",    "vv": 30, "speed": 0.96, "pitch": 2},
    "aqua":     {"voiceId": "anime-hina-ceria",      "vv": 69, "speed": 1.04, "pitch": 3},
    "atalanta": {"voiceId": "anime-hina-ceria",      "vv": 73, "speed": 1.12, "pitch": 2},
    "kali":     {"voiceId": "anime-reina-dewasa",    "vv": 77, "speed": 0.96, "pitch": 2},
    "zennyo":   {"voiceId": "anime-yui-lembut",      "vv": 15, "speed": 0.98, "pitch": 2},
    "rubby":    {"voiceId": "anime-lilith-menggoda", "vv": 5,  "speed": 0.98, "pitch": 2},
    "schylua":  {"voiceId": "anime-rei-sedih",       "vv": 61, "speed": 0.94, "pitch": 2},
    "vexira":   {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},
    "siv":      {"voiceId": "anime-momo-imut",       "vv": 60, "speed": 1.04, "pitch": 4},
    "sven":     {"voiceId": "anime-akane-kasar",     "vv": 6,  "speed": 1.02, "pitch": 3},  # Tsundere (Shikoku Metan Tsundere)
    "angela":   {"voiceId": "anime-yui-lembut",      "vv": 16, "speed": 0.98, "pitch": 2},
    "kara":     {"voiceId": "anime-reina-dewasa",    "vv": 23, "speed": 0.95, "pitch": 2},
    "mei":      {"voiceId": "anime-akane-kasar",     "vv": 7,  "speed": 1.05, "pitch": 2},
    "ninger":   {"voiceId": "anime-hina-ceria",      "vv": 68, "speed": 1.06, "pitch": 4},
    "spimei":   {"voiceId": "anime-rei-sedih",       "vv": 48, "speed": 0.98, "pitch": 2},
    "luby":     {"voiceId": "anime-momo-imut",       "vv": 58, "speed": 1.08, "pitch": 5},
    "gala":     {"voiceId": "anime-lilith-menggoda", "vv": 15, "speed": 0.96, "pitch": 2},
    "morana":   {"voiceId": "anime-reina-dewasa",    "vv": 16, "speed": 0.94, "pitch": 2},
    "seraph":   {"voiceId": "anime-yui-lembut",      "vv": 10, "speed": 1.02, "pitch": 3},
    "tamo":     {"voiceId": "anime-reina-dewasa",    "vv": 15, "speed": 0.96, "pitch": 2},
    "aura":     {"voiceId": "anime-akane-kasar",     "vv": 2,  "speed": 1.02, "pitch": 2},
    "fuji":     {"voiceId": "anime-yui-lembut",      "vv": 16, "speed": 0.96, "pitch": 2},
    "kyra":     {"voiceId": "anime-rika-marah",      "vv": 73, "speed": 1.02, "pitch": 2},
    "sharas":   {"voiceId": "anime-rika-marah",      "vv": 78, "speed": 1.06, "pitch": 2},
    "toka":     {"voiceId": "anime-hina-ceria",      "vv": 8,  "speed": 1.10, "pitch": 3},
    "tora":     {"voiceId": "anime-reina-dewasa",    "vv": 80, "speed": 0.98, "pitch": 2},
    "tsundae":  {"voiceId": "anime-lilith-menggoda", "vv": 4,  "speed": 0.96, "pitch": 3},  # Menggoda (Shikoku Metan Sexy)
    "vila":     {"voiceId": "anime-hina-ceria",      "vv": 68, "speed": 1.06, "pitch": 2},
    "yumi":     {"voiceId": "anime-momo-imut",       "vv": 45, "speed": 1.02, "pitch": 5},

    # --- 4 NPCs (100% Female Anime JP) ---
    "shop1":    {"voiceId": "anime-hina-ceria",      "vv": 8,  "speed": 1.05, "pitch": 2},
    "shop2":    {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},
    "hairly":   {"voiceId": "anime-reina-dewasa",    "vv": 16, "speed": 0.95, "pitch": 2},
    "grafity":  {"voiceId": "anime-akane-kasar",     "vv": 6,  "speed": 1.05, "pitch": 3},

    # --- 32 OTHER ENEMIES (100% Female Anime JP) ---
    "amatera":        {"voiceId": "anime-rei-sedih",       "vv": 25, "speed": 0.95, "pitch": 2},
    "anthis":         {"voiceId": "anime-yui-lembut",      "vv": 10, "speed": 0.95, "pitch": 3},
    "cleara":         {"voiceId": "anime-reina-dewasa",    "vv": 30, "speed": 0.96, "pitch": 2},
    "code_zero":      {"voiceId": "anime-rei-sedih",       "vv": 47, "speed": 0.98, "pitch": 2},
    "cow_girl":       {"voiceId": "anime-hina-ceria",      "vv": 70, "speed": 1.06, "pitch": 3},
    "eroghost":       {"voiceId": "anime-lilith-menggoda", "vv": 15, "speed": 0.95, "pitch": 3},
    "evy_blood_sage": {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},
    "ex_nymph":       {"voiceId": "anime-yui-lembut",      "vv": 46, "speed": 0.96, "pitch": 3},
    "graeae":         {"voiceId": "anime-rei-sedih",       "vv": 61, "speed": 0.94, "pitch": 2},
    "gumi_wolf":      {"voiceId": "anime-hina-ceria",      "vv": 54, "speed": 1.08, "pitch": 4},
    "kurenai":        {"voiceId": "anime-rika-marah",      "vv": 78, "speed": 1.02, "pitch": 2},
    "lamia":          {"voiceId": "anime-akane-kasar",     "vv": 6,  "speed": 1.02, "pitch": 2},
    "lizamorph":      {"voiceId": "anime-yui-lembut",      "vv": 60, "speed": 0.96, "pitch": 4},
    "lolth":          {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},
    "nagini":         {"voiceId": "anime-yui-lembut",      "vv": 15, "speed": 0.96, "pitch": 3},
    "nox":            {"voiceId": "anime-momo-imut",       "vv": 1,  "speed": 1.08, "pitch": 5},
    "octavia":        {"voiceId": "anime-lilith-menggoda", "vv": 16, "speed": 0.96, "pitch": 2},
    "octra":          {"voiceId": "anime-reina-dewasa",    "vv": 80, "speed": 0.96, "pitch": 2},
    "rin":            {"voiceId": "anime-akane-kasar",     "vv": 18, "speed": 1.02, "pitch": 2},
    "roza":           {"voiceId": "anime-rika-marah",      "vv": 73, "speed": 1.04, "pitch": 2},
    "scomantis":      {"voiceId": "anime-akane-kasar",     "vv": 7,  "speed": 1.05, "pitch": 3},
    "selene":         {"voiceId": "anime-lilith-menggoda", "vv": 66, "speed": 0.95, "pitch": 2},
    "serpentia":      {"voiceId": "anime-lilith-menggoda", "vv": 15, "speed": 0.95, "pitch": 2},
    "skelinch":       {"voiceId": "anime-hina-ceria",      "vv": 8,  "speed": 1.06, "pitch": 2},
    "slarkoi":        {"voiceId": "anime-akane-kasar",     "vv": 6,  "speed": 1.04, "pitch": 3},
    "slime":          {"voiceId": "anime-momo-imut",       "vv": 43, "speed": 1.08, "pitch": 5},
    "svormentis":     {"voiceId": "anime-reina-dewasa",    "vv": 30, "speed": 0.96, "pitch": 2},
    "veyr_nok":       {"voiceId": "anime-momo-imut",       "vv": 45, "speed": 1.00, "pitch": 5},
    "voodoo":         {"voiceId": "anime-momo-imut",       "vv": 58, "speed": 1.04, "pitch": 4},
    "xaniyus":        {"voiceId": "anime-yui-lembut",      "vv": 0,  "speed": 0.96, "pitch": 3},
    "ygg_naar":       {"voiceId": "anime-reina-dewasa",    "vv": 77, "speed": 0.94, "pitch": 2},
    "ymir":           {"voiceId": "anime-reina-dewasa",    "vv": 16, "speed": 0.96, "pitch": 2},
}


def post_json(url, payload, timeout=65):
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def download_file(url, dest_path, timeout=30):
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        with open(dest_path, "wb") as f:
            f.write(resp.read())


def process_and_save_wav(raw_audio_path, out_wav_path, is_freetts=False, pitch_factor=1.0):
    """Convert raw audio (WAV or MP3) to 22050Hz 16-bit mono WAV, strip FreeTTS watermark if present,
    restore feminine pitch if needed, trim leading/trailing dead silence, apply short fade in/out,
    and normalize peak to 0.88."""
    with tempfile.TemporaryDirectory() as td:
        conv_wav = os.path.join(td, "conv.wav")
        subprocess.run(
            ["afconvert", "-f", "WAVE", "-d", f"LEI16@{TARGET_SR}", "-c", "1", raw_audio_path, conv_wav],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        with wave.open(conv_wav, "rb") as w:
            sr = w.getframerate()
            samples = array.array("h", w.readframes(w.getnframes()))

    n = len(samples)
    if n == 0:
        raise RuntimeError("Empty audio buffer")

    # If generated by FreeTTS (freetts.org), strip the trailing ~2.7s English watermark
    # by searching BACKWARD from (n - 2.3s) for the silence gap (>=0.38s of abs(s) < 65) right before the watermark.
    if is_freetts and n > int(3.4 * sr):
        win = int(0.38 * sr)
        lo = max(int(0.15 * sr), n - int(5.2 * sr))
        hi = max(lo, n - int(2.3 * sr))
        run = 0
        for i in range(hi - 1, lo - 1, -1):
            if abs(samples[i]) < 65:
                run += 1
                if run >= win:
                    j = i
                    while j > lo and abs(samples[j - 1]) < 65:
                        j -= 1
                    cut_idx = min(n, j + int(0.08 * sr))
                    samples = samples[:cut_idx]
                    n = len(samples)
                    break
            else:
                run = 0

    # Trim leading and trailing silence (threshold ~ 1.2% of full scale = 400)
    thresh = 400
    first_idx = 0
    while first_idx < n and abs(samples[first_idx]) < thresh:
        first_idx += 1
    last_idx = n - 1
    while last_idx > first_idx and abs(samples[last_idx]) < thresh:
        last_idx -= 1

    if first_idx < last_idx:
        start = max(0, first_idx - int(0.03 * sr))
        end = min(n, last_idx + int(0.09 * sr))
        samples = samples[start:end]
        n = len(samples)

    # Restore feminine pitch if Voice Lab lowered basePitch for this speaker
    if abs(pitch_factor - 1.0) > 0.005 and n > 64:
        new_n = max(1, int(n / pitch_factor))
        resampled = array.array("h", [0] * new_n)
        for i in range(new_n):
            pos = i * pitch_factor
            idx = int(pos)
            frac = pos - idx
            if idx + 1 < n:
                val = samples[idx] * (1.0 - frac) + samples[idx + 1] * frac
            else:
                val = samples[min(idx, n - 1)]
            resampled[i] = int(max(-32768, min(32767, val)))
        samples = resampled
        n = len(samples)

    # Peak normalize to 0.88 * 32767 (~28835) and apply 12ms fade-in/out
    peak = max((abs(s) for s in samples), default=1)
    if peak < 1:
        peak = 1
    gain = min(3.5, 28835.0 / peak)
    fade_len = min(int(0.012 * sr), n // 4)

    out_samples = array.array("h", [0] * n)
    for i in range(n):
        val = samples[i] * gain
        if i < fade_len and fade_len > 0:
            val *= (i / fade_len)
        elif i >= n - fade_len and fade_len > 0:
            val *= ((n - 1 - i) / fade_len)
        if val > 32767:
            val = 32767
        elif val < -32768:
            val = -32768
        out_samples[i] = int(val)

    with wave.open(out_wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TARGET_SR)
        w.writeframes(out_samples.tobytes())


def load_report():
    if os.path.exists(PROGRESS_PATH):
        try:
            with open(PROGRESS_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "active_provider": "gemini-tts",
        "quota_events": [],
        "completed": {},
        "counts_by_engine": {"gemini": 0, "freetts": 0, "voicevox": 0},
    }


def save_report(rep):
    with open(PROGRESS_PATH, "w", encoding="utf-8") as f:
        json.dump(rep, f, ensure_ascii=False, indent=2)


def synthesize_line(cid, cat, jp_text, vcfg, rep):
    """Synthesize a single line following strict provider priority:
    gemini-tts -> freetts-api -> voicevox."""
    provider = rep.get("active_provider", "gemini-tts")
    voice_id = vcfg["voiceId"]
    vv_id = vcfg["vv"]
    speed = vcfg.get("speed", 1.0)
    raw_pitch = vcfg.get("pitch", 2)
    # Compensate for negative pitchOffset in Voice Lab so effective pitch is ALWAYS feminine (>0)
    compensated_pitch = raw_pitch + VOICE_PITCH_COMPENSATION.get(voice_id, 0)

    style_exag = 45 if cat in ("skill", "win", "hurt") else 25
    if cat == "ko":
        speed = max(0.78, round(speed * 0.92, 2))

    while True:
        payload = {
            "text": jp_text,
            "voiceId": voice_id,
            "provider": provider,
            "type": "tts",
            "settings": {
                "speed": speed,
                "pitch": compensated_pitch,
                "stability": 75,
                "similarity": 80,
                "styleExaggeration": style_exag,
                "speakerBoost": True,
                "voicevoxSpeakerId": vv_id if provider == "voicevox" else None,
            },
        }

        try:
            res = post_json(f"{VOICELAB_BASE}/api/generate", payload, timeout=75)
        except Exception as e:
            err_msg = str(e)
            if provider == "gemini-tts":
                event = f"Gemini TTS error/limit at {cid}_{cat} ({err_msg}) -> switching to freetts-api"
                print("  [!]", event, flush=True)
                rep["quota_events"].append({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "event": event, "char": cid, "cat": cat})
                rep["active_provider"] = "freetts-api"
                provider = "freetts-api"
                save_report(rep)
                continue
            elif provider == "freetts-api":
                event = f"FreeTTS error/limit at {cid}_{cat} ({err_msg}) -> switching to voicevox"
                print("  [!]", event, flush=True)
                rep["quota_events"].append({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "event": event, "char": cid, "cat": cat})
                rep["active_provider"] = "voicevox"
                provider = "voicevox"
                save_report(rep)
                continue
            else:
                raise

        gen = res.get("generation") or {}
        model = str(gen.get("model") or "")
        fb = str(res.get("fallbackNotice") or "")
        audio_url = str(gen.get("audioUrl") or "")

        if provider == "gemini-tts":
            if model.startswith("Gemini") and not fb:
                return audio_url, model, "gemini", False
            event = f"Gemini TTS quota exhausted at {cid}_{cat} (notice: {fb or model}) -> switching to freetts-api"
            print("  [!]", event, flush=True)
            rep["quota_events"].append({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "event": event, "char": cid, "cat": cat})
            rep["active_provider"] = "freetts-api"
            provider = "freetts-api"
            save_report(rep)
            if ("FreeTTS" in model or "Neural Turbo" in model) and audio_url:
                return audio_url, model, "freetts", ("FreeTTS" in model)
            continue

        if provider == "freetts-api":
            if ("FreeTTS" in model or "Neural Turbo" in model) and "429" not in fb:
                return audio_url, model, "freetts", ("FreeTTS" in model)
            event = f"FreeTTS quota exhausted at {cid}_{cat} (notice: {fb or model}) -> switching to voicevox"
            print("  [!]", event, flush=True)
            rep["quota_events"].append({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "event": event, "char": cid, "cat": cat})
            rep["active_provider"] = "voicevox"
            provider = "voicevox"
            save_report(rep)
            continue

        # provider == "voicevox"
        if not audio_url:
            raise RuntimeError(f"VoiceVox returned no audioUrl for {cid}_{cat}: {res}")
        return audio_url, model, "voicevox", False


def build_queue(vl, group="all", only_chars=None):
    queue = []
    if group in ("all", "heroes"):
        for hid in HERO_ORDER:
            if only_chars and hid not in only_chars:
                continue
            if hid in vl:
                for cat, pair in vl[hid]["lines"].items():
                    queue.append(("hero", hid, cat, pair[0]))
    if group in ("all", "npcs"):
        for nid in NPC_ORDER:
            if only_chars and nid not in only_chars:
                continue
            if nid in vl:
                for cat, pair in vl[nid]["lines"].items():
                    if nid == "hairly" and cat in ENEMY_HAIRLY_CATS:
                        continue
                    queue.append(("npc", nid, cat, pair[0]))
    if group in ("all", "enemies"):
        for eid in ENEMY_ORDER:
            if only_chars and eid not in only_chars:
                continue
            if eid in vl:
                for cat, pair in vl[eid]["lines"].items():
                    if eid == "hairly" and cat not in ENEMY_HAIRLY_CATS:
                        continue
                    queue.append(("enemy", eid, cat, pair[0]))
    return queue


def main():
    args = sys.argv[1:]
    group = "all"
    force = False
    only_chars = set()

    i = 0
    while i < len(args):
        if args[i] == "--group" and i + 1 < len(args):
            group = args[i + 1]
            i += 2
        elif args[i] == "--force":
            force = True
            i += 1
        elif args[i] == "--reset-provider" and i + 1 < len(args):
            rep = load_report()
            rep["active_provider"] = args[i + 1]
            save_report(rep)
            i += 2
        else:
            only_chars.add(args[i])
            i += 1

    with open(VL_PATH, "r", encoding="utf-8") as f:
        vl = json.load(f)

    rep = load_report()
    queue = build_queue(vl, group=group, only_chars=only_chars if only_chars else None)
    total = len(queue)
    print(f"=== Voice Lab Batch Generator === group={group} total_clips={total} active_provider={rep['active_provider']}", flush=True)

    done_count = 0
    for idx, (kind, cid, cat, jp_text) in enumerate(queue, 1):
        key = f"{cid}_{cat}"
        out_wav = os.path.join(OUT_DIR, f"{key}.wav")
        if not force and key in rep.get("completed", {}) and os.path.exists(out_wav) and os.path.getsize(out_wav) > 1000:
            done_count += 1
            continue

        vcfg = CHARACTER_VOICE_MAP.get(cid, {"voiceId": "anime-yui-lembut", "vv": 0, "speed": 1.0, "pitch": 2})
        t0 = time.time()
        audio_url, model, engine_key, is_freetts = synthesize_line(cid, cat, jp_text, vcfg, rep)

        pitch_factor = VV_PITCH_RESTORE.get(vcfg["vv"], 1.0) if engine_key == "voicevox" else 1.0
        full_url = audio_url if audio_url.startswith("http") else f"{VOICELAB_BASE}{audio_url}"
        ext = ".mp3" if ".mp3" in audio_url else ".wav"
        with tempfile.TemporaryDirectory() as td:
            raw_path = os.path.join(td, f"raw{ext}")
            download_file(full_url, raw_path)
            process_and_save_wav(raw_path, out_wav, is_freetts=is_freetts, pitch_factor=pitch_factor)

        # If hairly's bond line is also pet_3, copy to hairly_pet_3.wav as well
        if cid == "hairly" and cat == "bond":
            pet3_wav = os.path.join(OUT_DIR, "hairly_pet_3.wav")
            with open(out_wav, "rb") as src, open(pet3_wav, "wb") as dst:
                dst.write(src.read())

        dt = time.time() - t0
        rep["completed"][key] = {
            "group": kind,
            "char": cid,
            "cat": cat,
            "voiceId": vcfg["voiceId"],
            "voicevoxSpeakerId": vcfg["vv"],
            "engine": model,
            "engine_key": engine_key,
            "sec": round(dt, 2),
        }
        rep["counts_by_engine"][engine_key] = rep["counts_by_engine"].get(engine_key, 0) + 1
        save_report(rep)
        done_count += 1
        print(f"[{idx}/{total}] ({kind}) {key} -> {vcfg['voiceId']} (vv={vcfg['vv']}) via {model} ({dt:.1f}s)", flush=True)

    print(f"=== Completed {done_count}/{total} clips === Counts: {rep['counts_by_engine']}", flush=True)
    if rep["quota_events"]:
        print("Quota events:", json.dumps(rep["quota_events"][-6:], ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    main()
