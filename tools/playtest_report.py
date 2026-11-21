#!/usr/bin/env python3
"""Merge playtest logs (Settings > PLAYTEST DATA > SEND LOG) into retention / funnel numbers.

Usage:  python3 tools/playtest_report.py <file.json | folder> [...]

A file can also be the COPY TEXT version pasted into a .json/.txt file.
Same id twice (a tester sent the log again later) -> the export with the most events wins.
Day N retention counts only testers whose install is at least N days old at export time.
"""
import json, sys, os
from collections import Counter

def load(paths):
    files = []
    for p in paths:
        if os.path.isdir(p):
            files += [os.path.join(p, f) for f in sorted(os.listdir(p)) if f.endswith((".json", ".txt"))]
        else:
            files.append(p)
    logs = {}
    for f in files:
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception as e:
            print(f"skip {f}: {e}")
            continue
        if not isinstance(d, dict) or "events" not in d:
            print(f"skip {f}: not a playtest log")
            continue
        old = logs.get(d["id"])
        if old is None or len(d["events"]) > len(old["events"]):
            logs[d["id"]] = d
    return list(logs.values())

def pct(a, b):
    return "  -  " if b == 0 else f"{100 * a / b:4.0f}%"

def session_lengths(evs):
    by = {}
    for e in evs:
        s = e.get("s", 0)
        lo, hi = by.get(s, (e["t"], e["t"]))
        by[s] = (min(lo, e["t"]), max(hi, e["t"]))
    return {s: hi - lo for s, (lo, hi) in by.items()}

FUNNEL = [
    ("opened the game",        lambda e: e["e"] == "start"),
    ("reached the lobby",      lambda e: e["e"] == "scr" and e.get("n") == "lobby"),
    ("started a battle",       lambda e: e["e"] == "bat"),
    ("won a story battle",     lambda e: e["e"] == "bat" and e.get("m") == "story" and e.get("w") == 1),
    ("summoned",               lambda e: e["e"] == "pull"),
    ("opened hero upgrade",    lambda e: e["e"] == "scr" and e.get("n") == "hero_detail"),
    ("reached player Lv.5",    lambda e: e["e"] == "lvl" and e.get("l", 0) >= 5),
    ("reached player Lv.10",   lambda e: e["e"] == "lvl" and e.get("l", 0) >= 10),
]

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    logs = load(sys.argv[1:])
    n = len(logs)
    print(f"\n== EUPHORIA PLAYTEST REPORT  ({n} testers) ==")
    if n == 0:
        return
    plats = Counter()
    ret = {1: [0, 0], 3: [0, 0], 7: [0, 0]}
    first_len, total_min, sess_counts = [], [], []
    funnel = Counter()
    first_funnel = Counter()
    screens = Counter()
    quit_at = Counter()
    tuts = Counter()
    lose_at = Counter()
    for d in logs:
        evs = sorted(d["events"], key=lambda e: e["t"])
        inst = d["install"]
        age = (d.get("exported", evs[-1]["t"] if evs else inst) - inst) // 86400
        days = {(e["t"] - inst) // 86400 for e in evs}
        for k in ret:
            if age >= k:
                ret[k][1] += 1
                if any(x >= k for x in days):   # came back on day k or later
                    ret[k][0] += 1
        st = next((e for e in evs if e["e"] == "start"), None)
        if st:
            plats[st.get("plat", "?")] += 1
        lens = session_lengths(evs)
        sess_counts.append(len(lens))
        total_min.append(sum(lens.values()) / 60)
        if lens:
            first_len.append(lens[min(lens)] / 60)
        first_s = min(lens) if lens else 0
        for name, test in FUNNEL:
            if any(test(e) for e in evs):
                funnel[name] += 1
            if any(test(e) for e in evs if e.get("s") == first_s):
                first_funnel[name] += 1
        seen = {e["n"] for e in evs if e["e"] == "scr"}
        screens.update(seen)
        tuts.update({e["k"] for e in evs if e["e"] == "tut"})
        last_scr = [e.get("n") for e in evs if e["e"] == "scr"]
        if last_scr:
            quit_at[last_scr[-1]] += 1
        for e in evs:
            if e["e"] == "bat" and e.get("w") == 0:
                lose_at[f'{e.get("m")} {e.get("st", "")}'.strip()] += 1

    def med(xs):
        xs = sorted(xs)
        return xs[len(xs) // 2] if xs else 0

    print("\nPlatforms: " + ", ".join(f"{k} {v}" for k, v in plats.most_common()))
    print("\nRETENTION (came back on day N or later; only testers old enough)")
    for k, (a, b) in ret.items():
        print(f"  D{k}: {a}/{b}  {pct(a, b)}")
    print(f"\nFirst session median: {med(first_len):.1f} min   |   total play median: {med(total_min):.1f} min   |   sessions median: {med(sess_counts)}")
    print("\nFUNNEL                      first session    ever")
    for name, _ in FUNNEL:
        print(f"  {name:<24} {first_funnel[name]:>4} {pct(first_funnel[name], n)}   {funnel[name]:>4} {pct(funnel[name], n)}")
    print("\nLAST SCREEN BEFORE THEY STOPPED (where people drop off)")
    for k, v in quit_at.most_common(10):
        print(f"  {k:<24} {v:>4} {pct(v, n)}")
    print("\nSCREENS OPENED (share of testers who ever opened it)")
    for k, v in screens.most_common():
        print(f"  {k:<24} {v:>4} {pct(v, n)}")
    print("\nMOST LOST BATTLES (difficulty walls)")
    for k, v in lose_at.most_common(10):
        print(f"  {k:<24} {v:>4}")
    print("\nTUTORIALS SHOWN")
    for k, v in tuts.most_common(15):
        print(f"  {k:<24} {v:>4}")
    print()

if __name__ == "__main__":
    main()
