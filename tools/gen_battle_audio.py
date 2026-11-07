"""Procedural battle SFX + BGM for Euphoria Online (run once: python3 tools/gen_battle_audio.py)."""
import numpy as np, wave, os
SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'audio', 'battle')
rng = np.random.default_rng(7)

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=0.2, shape=3.0):
    x = np.ones(n); na = max(1, int(SR * a)); x[:na] = np.linspace(0, 1, na)
    tail = np.linspace(1, 0, n - na) ** shape; x[na:] *= tail; return x
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, k):  # one-pole lowpass, k in (0,1]
    y = np.zeros_like(x); s = 0.0
    for i, v in enumerate(x): s += k * (v - s); y[i] = s
    return y
def hp(x, k): return x - lp(x, k)
def sweep(f0, f1, d, wave_='sine'):
    tt = t(d); f = np.geomspace(f0, f1, len(tt)); ph = 2 * np.pi * np.cumsum(f) / SR
    if wave_ == 'saw': return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if wave_ == 'square': return np.sign(np.sin(ph))
    return np.sin(ph)
def tone(f, d, wave_='sine'): return sweep(f, f, d, wave_)
def mix(*xs):
    n = max(len(x) for x in xs); o = np.zeros(n)
    for x in xs: o[:len(x)] += x
    return o
def pad(x, at):
    return np.concatenate([np.zeros(int(SR * at)), x])
def save(name, x, vol=0.8, stereo_w=0.0):
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    l = x; r = x
    if stereo_w:
        d = int(SR * 0.012); r = np.concatenate([np.zeros(d), x])[:len(x)]
        l = x * (1 - stereo_w) + r * stereo_w
    data = (np.stack([l, r], 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

# ---- SFX
save('slash', hp(noise(0.22), 0.35) * env(int(SR*.22), .002, .2, 2) + 0.4 * sweep(1800, 400, .22) * env(int(SR*.22), .001, .2, 4))
save('hit', mix(lp(noise(.18), .25) * env(int(SR*.18), .001, .18, 4), 0.9 * sweep(160, 50, .18) * env(int(SR*.18), .001, .18, 2)))
save('crit', mix(hp(noise(.3), .5) * env(int(SR*.3), .001, .3, 5), sweep(220, 40, .3) * env(int(SR*.3), .001, .3, 2), 0.35 * tone(1760, .5) * env(int(SR*.5), .002, .5, 3), 0.25 * tone(2637, .5) * env(int(SR*.5), .002, .5, 3)), 0.9)
save('cast', mix(*[pad(0.5 * tone(f, .35) * env(int(SR*.35), .01, .35, 2), i * .06) for i, f in enumerate([523, 659, 784, 1047, 1319])]), stereo_w=.4)
save('heal', mix(*[pad(0.4 * tone(f, .9) * env(int(SR*.9), .02, .9, 2) * (1 + .3 * np.sin(2*np.pi*6*t(.9))), i * .08) for i, f in enumerate([880, 1109, 1319, 1760])]), 0.6, .5)
save('buff', mix(sweep(300, 1200, .45, 'square') * 0.2 * env(int(SR*.45), .01, .45, 1.5), 0.4 * sweep(600, 2400, .45) * env(int(SR*.45), .01, .45, 2)), 0.6)
save('debuff', mix(sweep(900, 150, .5, 'saw') * 0.3 * env(int(SR*.5), .01, .5, 1.5), 0.3 * sweep(450, 80, .5) * env(int(SR*.5), .01, .5, 2)), 0.6)
fire = lp(noise(.8), .08) * env(int(SR*.8), .02, .8, 1.5) * (1 + 0.5 * np.sin(2*np.pi*13*t(.8)))
save('fire', mix(fire, 0.6 * sweep(120, 40, .8) * env(int(SR*.8), .005, .8, 2)), 0.85)
ice = mix(*[pad(0.35 * tone(f, .5) * env(int(SR*.5), .001, .5, 6), d) for f, d in [(2093, 0), (2637, .05), (3136, .11), (2349, .16), (3520, .22)]])
save('ice', mix(ice, 0.5 * hp(noise(.25), .7) * env(int(SR*.25), .001, .25, 3)), 0.75, .5)
crack = hp(noise(.12), .6) * env(int(SR*.12), .0005, .12, 2)
rumble = lp(noise(1.0), .02) * env(int(SR*1.0), .01, 1.0, 1.5)
save('thunder', mix(crack, pad(crack * .7, .05), pad(rumble * 1.6, .03)), 0.9, .3)
save('wind', lp(hp(noise(.7), .2), .25) * np.sin(np.linspace(0, np.pi, int(SR*.7))) ** 2 * (1 + .6 * np.sin(2*np.pi*5*t(.7))), 0.7, .6)
save('earth', mix(sweep(90, 30, .6) * env(int(SR*.6), .001, .6, 2), lp(noise(.6), .05) * 1.5 * env(int(SR*.6), .001, .6, 2), pad(lp(noise(.2), .2) * env(int(SR*.2), .001, .2, 3) * .5, .08)), 0.95)
save('light', mix(*[0.3 * tone(f, 1.0) * env(int(SR*1.0), .05, 1.0, 2) for f in [1047, 1319, 1568, 2093]], 0.4 * hp(noise(1.0), .8) * env(int(SR*1.0), .3, 1.0, 2) * .3), 0.6, .5)
save('dark', mix(sweep(300, 60, .9, 'saw') * 0.4 * env(int(SR*.9), .02, .9, 1.5), sweep(305, 58, .9, 'saw') * 0.4 * env(int(SR*.9), .02, .9, 1.5), lp(noise(.9), .05) * env(int(SR*.9), .1, .9, 1.2)), 0.8, .4)
save('water', mix(lp(noise(.5), .15) * env(int(SR*.5), .005, .5, 2), *[pad(0.3 * sweep(f, f * 1.8, .08) * env(int(SR*.08), .001, .08, 2), d) for f, d in [(400, 0), (600, .07), (500, .14), (700, .2)]]), 0.7, .4)
save('death', mix(sweep(600, 80, .8, 'square') * 0.25 * env(int(SR*.8), .005, .8, 1.5), lp(noise(.8), .1) * env(int(SR*.8), .005, .8, 2)), 0.6)
save('dash', lp(hp(noise(.25), .3), .5) * np.sin(np.linspace(0, np.pi, int(SR*.25))) ** 2, 0.5)
gong = mix(*[0.4 / (i + 1) * tone(110 * h, 2.0) * env(int(SR*2.0), .002, 2.0, 1.5) for i, h in enumerate([1, 2.4, 3.9, 5.4])])
save('round', mix(gong, 0.4 * lp(noise(.1), .3) * env(int(SR*.1), .001, .1, 2)), 0.7)

# ---- BGM loops
def drum_loop(bpm, bars, boss=False):
    beat = 60 / bpm; total = beat * 4 * bars; n = int(SR * total); out = np.zeros(n)
    kick = sweep(150, 45, .25) * env(int(SR*.25), .001, .25, 3)
    snare = hp(noise(.18), .4) * env(int(SR*.18), .001, .18, 3) * .6 + tone(190, .18) * env(int(SR*.18), .001, .18, 4) * .3
    hat = hp(noise(.05), .85) * env(int(SR*.05), .001, .05, 4) * .25
    def put(x, at):
        i = int(SR * at); j = min(n, i + len(x)); out[i:j] += x[:j - i]
    for b in range(bars * 4):
        tb = b * beat
        put(kick, tb)
        if boss and b % 2 == 1: put(kick, tb + beat / 2)
        if b % 2 == 1: put(snare, tb)
        for k in range(2): put(hat, tb + k * beat / 2)
    return out, beat

def music(name, bpm, bars, root, boss=False):
    drums, beat = drum_loop(bpm, bars, boss)
    n = len(drums); bass = np.zeros(n); lead = np.zeros(n); padv = np.zeros(n)
    prog = [0, -4, -2, -5] if not boss else [0, 1, -2, -1]   # minor feel
    minor = [0, 3, 7, 10, 12, 15]
    def put(arr, x, at):
        i = int(SR * at); j = min(n, i + len(x)); arr[i:j] += x[:j - i]
    for bar in range(bars):
        chord = root * 2 ** (prog[bar % 4] / 12)
        for e in range(8):
            f = chord / 2 * (1.5 if e % 4 == 3 else 1)
            note = tone(f, beat / 2, 'saw')
            put(bass, lp(note, .08) * env(len(note), .005, beat / 2, 1.5), (bar * 8 + e) * beat / 2)
        for s in range(16):
            iv = minor[(s * 3 + bar) % len(minor)] if boss else minor[[0, 2, 1, 3, 2, 4, 3, 1][s % 8]]
            f = chord * 2 * 2 ** (iv / 12)
            note = tone(f, beat / 4, 'square') * .5 + tone(f * 2, beat / 4) * .3
            put(lead, note * env(len(note), .003, beat / 4, 2), (bar * 16 + s) * beat / 4)
        for iv in (0, 3, 7):
            f = chord * 2 ** (iv / 12)
            p = tone(f, beat * 4) + tone(f * 1.003, beat * 4)
            put(padv, p * env(len(p), .3, beat * 4, .8) * .5, bar * beat * 4)
    x = drums * 1.0 + lp(bass, .3) * .55 + lp(lead, .35) * (.22 if not boss else .28) + lp(padv, .05) * .25
    save(name, x, 0.7, .3)

music('bgm_battle', 138, 8, 220.0)
music('bgm_boss', 150, 8, 196.0, True)
print('ok', sorted(os.listdir(OUT)))
