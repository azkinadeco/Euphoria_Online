#!/usr/bin/env python3
"""Synthesises the small UI sounds (audio/ui/*.wav): popup open / close, tab, error, reward, confirm.

Run from the project root:  python3 tools/gen_ui_audio.py   (needs numpy)
All sounds are short, soft and mono 44.1 kHz so they sit under the music.
"""
import os
import wave

import numpy as np

SR = 44100
OUT = 'audio/ui'


def env(n, attack, release):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((n / SR - t) / max(release, 1e-4), 0, 1)
    return a * r ** 1.6


def tone(freq, dur, attack=0.004, release=None, harm=((1, 1.0), (2, 0.25), (3, 0.08))):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = freq if np.isscalar(freq) else np.asarray(freq)
    ph = 2 * np.pi * np.cumsum(np.full(n, f) if np.isscalar(f) else f) / SR
    y = sum(a * np.sin(ph * k) for k, a in harm)
    return y * env(n, attack, release if release else dur * 0.9)


def noise_sweep(dur, f0, f1, q=0.25):
    """Band-limited noise whose centre glides from f0 to f1 (a soft whoosh)."""
    n = int(SR * dur)
    rng = np.random.default_rng(7)
    x = rng.standard_normal(n)
    y = np.zeros(n)
    lp = bp = 0.0
    for i in range(n):
        fc = f0 + (f1 - f0) * (i / n)
        f = 2 * np.sin(np.pi * fc / SR)
        hp = x[i] - lp - q * bp
        bp += f * hp
        lp += f * bp
        y[i] = bp
    return y * env(n, dur * 0.25, dur * 0.7)


def glide(f0, f1, dur):
    n = int(SR * dur)
    return np.linspace(f0, f1, n)


def mix(*parts):
    n = max(len(p) for p in parts)
    y = np.zeros(n)
    for p in parts:
        y[:len(p)] += p
    return y


def at(y, delay):
    return np.concatenate([np.zeros(int(SR * delay)), y])


def save(name, y, gain):
    y = y / max(1e-9, np.abs(y).max()) * gain
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((y * 32767).astype('<i2').tobytes())
    print('%-10s %.2fs' % (name, len(y) / SR))


def main():
    # popup opens: airy upward whoosh with a faint high note
    save('open', mix(noise_sweep(0.16, 700, 2600) * 0.9, tone(glide(620, 930, 0.14), 0.14) * 0.35), 0.42)
    # popup closes: the same, falling and shorter
    save('close', mix(noise_sweep(0.12, 2200, 600) * 0.9, tone(glide(820, 520, 0.1), 0.1) * 0.3), 0.36)
    # tab / filter: a tiny wooden tick
    save('tab', mix(tone(1250, 0.045, 0.001, 0.04), tone(2500, 0.03, 0.001, 0.025) * 0.3), 0.4)
    # error / not enough: two soft low notes going down
    save('error', mix(tone(233, 0.11, 0.004, 0.1, ((1, 1.0), (2, 0.5), (3, 0.3))), at(tone(185, 0.16, 0.004, 0.15, ((1, 1.0), (2, 0.5), (3, 0.3))), 0.09)), 0.4)
    # reward: a rising three-note chime with a sparkle on top
    notes = [(784, 0.0), (988, 0.07), (1319, 0.14)]
    chime = mix(*[at(tone(f, 0.42, 0.003, 0.4, ((1, 1.0), (2, 0.35), (4, 0.12))), d) for f, d in notes])
    save('reward', mix(chime, at(tone(2637, 0.3, 0.002, 0.28) * 0.25, 0.2)), 0.5)
    # confirm / important action: one warm bell
    save('studio_open', studio_open(), 0.62)
    save('confirm', mix(tone(660, 0.3, 0.003, 0.28, ((1, 1.0), (2, 0.4), (3, 0.15))), at(tone(990, 0.26, 0.003, 0.24) * 0.5, 0.05)), 0.45)


def studio_open():
    """ONIX Studio logo sting (~2.6 s): a soft low swell, a glassy open-fifth chord that blooms with the
    light sweep, a few high sparkles and a long airy tail. Minimal: no melody, no drums."""
    dur = 2.8
    n = int(SR * dur)
    t = np.arange(n) / SR
    # sub swell: 55 Hz + 110 Hz, rising for 0.5 s then decaying
    swell = (np.sin(2 * np.pi * 55 * t) * 0.6 + np.sin(2 * np.pi * 110 * t) * 0.3)
    swell *= np.clip(t / 0.5, 0, 1) ** 2 * np.exp(-np.clip(t - 0.5, 0, None) * 1.6)
    # glassy chord (A3, E4, A4, E5 with slight detune) entering at 0.35 s, bell-like decay
    chord = np.zeros(n)
    for f, a in [(220.0, 0.5), (329.6, 0.45), (440.0, 0.4), (659.3, 0.28), (880.0, 0.12)]:
        for det in (-0.6, 0.6):
            ph = 2 * np.pi * (f + det) * t
            chord += a * (np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3.01 * ph))
    st = 0.35
    env_c = np.clip((t - st) / 0.06, 0, 1) * np.exp(-np.clip(t - st, 0, None) * 1.35)
    chord *= env_c * 0.22
    # sparkles: short high pings scattered over the bloom
    rng = np.random.default_rng(3)
    spark = np.zeros(n)
    for k in range(9):
        t0 = 0.45 + k * 0.11 + rng.uniform(0, 0.05)
        f = rng.choice([1760.0, 2217.5, 2637.0, 3520.0])
        e = np.clip((t - t0) / 0.004, 0, 1) * np.exp(-np.clip(t - t0, 0, None) * 9.0) * (t >= t0)
        spark += np.sin(2 * np.pi * f * t) * e * (0.5 - k * 0.04)
    spark *= 0.12
    # airy tail: filtered noise that breathes in with the chord and fades out slowly
    air = noise_sweep(dur, 3200, 1400, 0.35)
    air *= np.clip((t - 0.3) / 0.5, 0, 1) * np.exp(-np.clip(t - 0.8, 0, None) * 1.2) * 0.35
    y = swell * 0.55 + chord + spark + air
    # gentle stereo-free reverb: a few decaying echoes
    out = y.copy()
    for d, g in [(0.061, 0.28), (0.113, 0.2), (0.187, 0.14), (0.293, 0.09)]:
        k = int(SR * d)
        out[k:] += y[:-k] * g
    fade = np.clip((dur - t) / 0.4, 0, 1)
    return out * fade


if __name__ == '__main__':
    main()
