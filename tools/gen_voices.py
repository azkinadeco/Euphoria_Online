"""Generate hero voice lines with macOS TTS (Japanese voice "Kyoko").
Each hero gets her own pitch/speed from data/voice_lines.json.
Run: python3 tools/gen_voices.py [hero_id ...]   (macOS only)"""
import json, os, subprocess, sys, tempfile, wave
import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'audio', 'voice')
SR = 22050
os.makedirs(OUT, exist_ok=True)
data = json.load(open(os.path.join(ROOT, 'data', 'voice_lines.json'), encoding='utf-8'))
only = set(sys.argv[1:])

def read_wav(p):
    with wave.open(p) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
        if w.getnchannels() == 2:
            x = x.reshape(-1, 2).mean(1)
        return x, w.getframerate()

def write_wav(p, x):
    x = np.clip(x, -1, 1)
    with wave.open(p, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())

for hid, h in data.items():
    if only and hid not in only:
        continue
    pitch = float(h.get('pitch', 1.15)); rate = int(h.get('rate', 180))
    for cat, (jp, en) in h['lines'].items():
        with tempfile.TemporaryDirectory() as td:
            tmp = os.path.join(td, 'v.wav')
            subprocess.run(['say', '-v', 'Kyoko', '-r', str(int(rate / pitch)), '-o', tmp,
                            '--file-format=WAVE', '--data-format=LEI16@%d' % SR, jp], check=True)
            x, sr = read_wav(tmp)
        # pitch up (resample) -> brighter, younger tone
        n = int(len(x) / pitch)
        x = np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)
        # gentle presence boost: add a little of the high-passed signal
        hp = x - np.convolve(x, np.ones(6) / 6, mode='same')
        x = x + 0.35 * hp
        # trim silence, short fades, normalize
        idx = np.nonzero(np.abs(x) > 0.02)[0]
        if len(idx):
            x = x[max(0, idx[0] - 200): idx[-1] + 1200]
        f = min(300, len(x) // 4)
        x[:f] *= np.linspace(0, 1, f); x[-f:] *= np.linspace(1, 0, f)
        x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
        write_wav(os.path.join(OUT, '%s_%s.wav' % (hid, cat)), x)
    print('voiced', hid)
