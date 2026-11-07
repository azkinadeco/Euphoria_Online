"""Placeholder BGM until a composer delivers real tracks. Replace the .wav files with the same names.
Run: python3 tools/gen_music.py  -> audio/bgm_lobby.wav, audio/bgm_story.wav, audio/bgm_gacha.wav"""
import numpy as np, wave, os
SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'audio')

def note(f, dur, kind='piano'):
    t = np.arange(int(SR * dur)) / SR
    if kind == 'piano':
        x = sum(a * np.sin(2 * np.pi * f * h * t) for h, a in [(1, 1.0), (2, 0.35), (3, 0.15), (4, 0.06)])
        env = np.exp(-t * 2.8) * np.minimum(1, t * 200)
    elif kind == 'bell':
        x = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t)
        env = np.exp(-t * 2.0) * np.minimum(1, t * 300)
    elif kind == 'harp':
        x = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t)
        env = np.exp(-t * 4.0) * np.minimum(1, t * 400)
    else:  # pad / strings
        x = sum(np.sin(2 * np.pi * f * d * t + d) for d in (1.0, 1.004, 0.996)) / 3 + 0.25 * np.sin(2 * np.pi * f * 2 * t)
        env = np.minimum(1, t / (dur * 0.35)) * np.minimum(1, (dur - t) / (dur * 0.35))
    return x * env

def hz(n):  # midi -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)

def reverb(x, mix=0.3):
    y = x.copy()
    for d, g in [(0.031, 0.5), (0.047, 0.45), (0.071, 0.4), (0.113, 0.35), (0.161, 0.3)]:
        k = int(SR * d)
        z = np.zeros_like(x); z[k:] = x[:-k] * g
        for _ in range(3):
            z2 = np.zeros_like(z); z2[k:] = z[:-k] * g; z = z + z2
        y = y + z * mix / 3
    return y

def song(name, bpm, prog, scale_root, melody, bars=8, lead='piano', pad=True, arp='harp', vol=0.6):
    beat = 60 / bpm; n = int(SR * beat * 4 * bars); out = np.zeros(n + SR * 2)
    def put(x, at, g=1.0):
        i = int(SR * at); out[i:i + len(x)] += x[:max(0, len(out) - i)] * g
    for b in range(bars):
        root = scale_root + prog[b % len(prog)]
        chord = [root, root + (3 if prog[b % len(prog)] in (9, -3) else 4), root + 7]
        if pad:
            for c in chord:
                put(note(hz(c - 12), beat * 4, 'pad'), b * beat * 4, 0.16)
        put(note(hz(root - 24), beat * 4, 'pad'), b * beat * 4, 0.22)
        for k in range(8):
            c = chord[[0, 1, 2, 1, 0, 2, 1, 2][k]] + (12 if k >= 4 else 0)
            put(note(hz(c), beat * 0.9, arp), (b * 8 + k) * beat / 2, 0.18)
        for k, m in enumerate(melody[b % len(melody)]):
            if m is not None:
                put(note(hz(scale_root + 12 + m), beat * 1.6, lead), (b * 4 + k) * beat, 0.32)
    out = reverb(out[:n + SR], 0.45)
    # crossfade tail into head for a seamless loop
    tail = out[n:n + SR]; out = out[:n]; out[:SR] += tail * np.linspace(1, 0, SR)
    out = out / (np.max(np.abs(out)) + 1e-9) * vol
    st = np.stack([out, np.roll(out, int(SR * 0.012))], 1)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((st * 32767).astype(np.int16).tobytes())
    print(name, round(n / SR, 1), 's')

# Lobby: warm, hopeful (C major: I - V - vi - IV)
song('bgm_lobby', 78, [0, 7, 9, 5], 60,
     [[4, 7, 9, 7], [11, 9, 7, 4], [12, 11, 9, 7], [9, 7, 5, 4], [4, 7, 12, 11], [9, 7, 4, 2], [5, 4, 2, 0], [2, None, 0, None]], lead='piano')
# Story: wistful adventure (A minor: i - VI - III - VII)
song('bgm_story', 72, [-3, 5, 0, 7], 57,
     [[0, 3, 7, 5], [3, 2, 0, -2], [7, 8, 7, 3], [2, 0, None, None]], lead='bell', arp='harp')
# Gacha: mystical anticipation (D minor-ish, bells)
song('bgm_gacha', 92, [2, -2, 0, 5], 62,
     [[7, 9, 10, 12], [14, 12, 10, 9], [7, 5, 7, 9], [10, None, 9, None]], lead='bell', arp='bell', vol=0.5)
