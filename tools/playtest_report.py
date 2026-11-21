#!/usr/bin/env python3
"""Merge playtest logs (Settings > PLAYTEST DATA > SEND LOG) into retention / funnel numbers.

Usage:  python3 tools/playtest_report.py <file.json | folder> [...] [--build <prefix>] [--csv out.csv]

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
    ("cleared chapter 1",      lambda e: e["e"] == "bat" and e.get("m") == "story" and e.get("w") == 1 and e.get("st") == "s5"),
    ("reached player Lv.5",    lambda e: e["e"] == "lvl" and e.get("l", 0) >= 5),
    ("reached player Lv.10",   lambda e: e["e"] == "lvl" and e.get("l", 0) >= 10),
]

MILESTONES = [
    ("first battle won",   lambda e: e["e"] == "bat" and e.get("w") == 1),
    ("first summon",       lambda e: e["e"] == "pull"),
    ("chapter 1 cleared",  lambda e: e["e"] == "bat" and e.get("m") == "story" and e.get("w") == 1 and e.get("st") == "s5"),
    ("player Lv.10",       lambda e: e["e"] == "lvl" and e.get("l", 0) >= 10),
]

def play_minutes_at(evs, lens, target):
    """Minutes of play (session time only) before event `target`."""
    starts = {}
    for e in evs:
        starts.setdefault(e.get("s", 0), e["t"])
    before = sum(v for s, v in lens.items() if s < target.get("s", 0))
    return (before + target["t"] - starts.get(target.get("s", 0), target["t"])) / 60

def med(xs):
    xs = sorted(xs)
    return xs[len(xs) // 2] if xs else 0

def main():
    args = sys.argv[1:]
    build = None
    csv_out = None
    if "--build" in args:
        k = args.index("--build"); build = args[k + 1]; del args[k:k + 2]
    if "--csv" in args:
        k = args.index("--csv"); csv_out = args[k + 1]; del args[k:k + 2]
    if not args:
        print(__doc__)
        sys.exit(1)
    logs = load(args)
    if build:
        logs = [d for d in logs if str(d.get("build", "")).startswith(build)]
    n = len(logs)
    print(f"\n== EUPHORIA PLAYTEST REPORT  ({n} testers{', build ' + build if build else ''}) ==")
    if n == 0:
        return
    plats, builds = Counter(), Counter()
    ret = {1: [0, 0], 3: [0, 0], 7: [0, 0]}
    first_len, total_min, sess_counts = [], [], []
    funnel, first_funnel = Counter(), Counter()
    screens, quit_at, tuts, lose_at = Counter(), Counter(), Counter(), Counter()
    miles = {m: [] for m, _ in MILESTONES}
    boot = {"title": [], "lobby": []}
    fps = {}
    walls, shorts, bquits, lpicks = Counter(), Counter(), Counter(), Counter()
    art_secs, art_errs = [], Counter()   # deferred HD art packs (game/core/art_pack.gd)
    vn = {"story": [0, 0, 0], "tutorial": [0, 0, 0]}   # scenes, skipped, lines read share sum
    ratings = {}
    rtags = Counter()
    feedback = []
    rows = []
    for d in logs:
        evs = sorted(d["events"], key=lambda e: e["t"])
        inst = d["install"]
        age = (d.get("exported", evs[-1]["t"] if evs else inst) - inst) // 86400
        days = {(e["t"] - inst) // 86400 for e in evs}
        returned = {}
        for k in ret:
            if age >= k:
                ret[k][1] += 1
                returned[k] = any(x >= k for x in days)
                if returned[k]:
                    ret[k][0] += 1
        st = next((e for e in evs if e["e"] == "start"), None)
        plats[st.get("plat", "?") if st else "?"] += 1
        builds[str(d.get("build", st.get("b", "?") if st else "?"))] += 1
        lens = session_lengths(evs)
        sess_counts.append(len(lens))
        total = sum(lens.values()) / 60
        total_min.append(total)
        if lens:
            first_len.append(lens[min(lens)] / 60)
        first_s = min(lens) if lens else 0
        for name, test in FUNNEL:
            if any(test(e) for e in evs):
                funnel[name] += 1
            if any(test(e) for e in evs if e.get("s") == first_s):
                first_funnel[name] += 1
        for name, test in MILESTONES:
            hit = next((e for e in evs if test(e)), None)
            if hit:
                miles[name].append(play_minutes_at(evs, lens, hit))
        screens.update({e["n"] for e in evs if e["e"] == "scr"})
        tuts.update({e["k"] for e in evs if e["e"] == "tut"})
        last_scr = [e.get("n") for e in evs if e["e"] == "scr"]
        if last_scr:
            quit_at[last_scr[-1]] += 1
        for e in evs:
            k = e["e"]
            if k == "bat" and e.get("w") == 0:
                lose_at[f'{e.get("m")} {e.get("st", "")}'.strip()] += 1
            elif k == "scr":
                if "ms" in e and e.get("n") in boot:
                    boot[e["n"]].append(e["ms"] / 1000)
                if "pf" in e and e.get("from"):
                    fps.setdefault(e["from"], []).append((e["pf"], e.get("plo", e["pf"])))
            elif k == "beat" and "f" in e:
                fps.setdefault(e.get("n", "?"), []).append((e["f"], e.get("lo", e["f"])))
            elif k == "wall":
                walls[f'{e.get("m")}: {e.get("why", "")}'] += 1
            elif k == "short":
                shorts[e.get("k", "?")] += 1
            elif k == "bquit":
                bquits[f'{e.get("m")} {e.get("st", "")}'.strip()] += 1
            elif k == "artpack":
                art_secs.append(e.get("sec", 0))
            elif k == "artpack_err":
                art_errs[str(e.get("why", "?"))] += 1
            elif k == "lpick":
                lpicks[e.get("c", "?")] += 1
            elif k == "vn":
                kind = "tutorial" if e.get("tut") else "story"
                vn[kind][0] += 1
                vn[kind][1] += e.get("sk", 0)
                vn[kind][2] += e.get("r", 0) / max(1, e.get("n", 1))
            elif k == "rate":
                if e.get("v", 0) > 0:
                    ratings.setdefault(e.get("k", "?"), []).append(e["v"])
                rtags.update([x for x in str(e.get("tags", "")).split(",") if x])
        for f in d.get("feedback", []):
            feedback.append((d["id"], f.get("scr", ""), f.get("txt", "")))
        rows.append({"id": d["id"], "build": d.get("build", ""), "platform": st.get("plat", "") if st else "",
                     "days_active": len(days), "sessions": len(lens), "play_min": round(total, 1),
                     "d1": returned.get(1, ""), "d7": returned.get(7, ""),
                     "max_level": max([e.get("l", 1) for e in evs if e["e"] == "lvl"] or [1]),
                     "last_screen": last_scr[-1] if last_scr else ""})

    print("\nPlatforms: " + ", ".join(f"{k} {v}" for k, v in plats.most_common()))
    print("Builds:    " + ", ".join(f"{k} {v}" for k, v in builds.most_common()))
    print("\nRETENTION (came back on day N or later; only testers old enough)")
    for k, (a, b) in ret.items():
        print(f"  D{k}: {a}/{b}  {pct(a, b)}")
    print(f"\nFirst session median: {med(first_len):.1f} min   |   total play median: {med(total_min):.1f} min   |   sessions median: {med(sess_counts)}")
    print("\nFUNNEL                      first session    ever")
    for name, _ in FUNNEL:
        print(f"  {name:<24} {first_funnel[name]:>4} {pct(first_funnel[name], n)}   {funnel[name]:>4} {pct(funnel[name], n)}")
    print("\nPLAY TIME UNTIL (median minutes, testers who got there)")
    for name, xs in miles.items():
        print(f"  {name:<24} {med(xs):6.1f} min   ({len(xs)} testers)")
    print("\nLAST SCREEN BEFORE THEY STOPPED (where people drop off)")
    for k, v in quit_at.most_common(10):
        print(f"  {k:<24} {v:>4} {pct(v, n)}")
    print("\nSCREENS OPENED (share of testers who ever opened it)")
    for k, v in screens.most_common():
        print(f"  {k:<24} {v:>4} {pct(v, n)}")
    print("\nPERFORMANCE")
    for k, xs in boot.items():
        if xs:
            print(f"  boot to {k:<16} median {med(xs):5.1f} s   worst {max(xs):5.1f} s")
    if art_secs:
        print(f"  HD art packs all loaded  median {med(art_secs):5.0f} s   worst {max(art_secs):5.0f} s   ({len(art_secs)} sessions)")
    if art_errs:
        print("  HD art download errors: " + ", ".join(f"{k} x{v}" for k, v in art_errs.most_common(5)))
    print("  screen                   avg fps   low fps   samples   (sorted worst first)")
    for k, xs in sorted(fps.items(), key=lambda kv: med([a for a, _ in kv[1]]))[:15]:
        print(f"  {k:<24} {med([a for a, _ in xs]):7.0f}   {med([b for _, b in xs]):7.0f}   {len(xs):7}")
    print("\nMOST LOST BATTLES (difficulty walls)")
    for k, v in lose_at.most_common(10):
        print(f"  {k:<24} {v:>4}")
    print(f"  after a defeat they picked: " + (", ".join(f"{k} {v}" for k, v in lpicks.most_common()) or "-"))
    print("\nBATTLES LEFT HALF-WAY (app closed / screen left)")
    for k, v in bquits.most_common(8):
        print(f"  {k:<24} {v:>4}")
    print("\nECONOMY WALLS")
    for k, v in walls.most_common(8):
        print(f"  {v:>4}  {k}")
    print("  could not afford: " + (", ".join(f"{k} {v}" for k, v in shorts.most_common()) or "-"))
    print("\nSTORY / TUTORIAL TEXT")
    for k, (c, sk, rd) in vn.items():
        if c:
            print(f"  {k:<10} {c:>5} scenes   skipped {pct(sk, c)}   lines read {pct(rd, c)}")
    print("\nQUICK RATINGS (1-5)")
    for k, xs in sorted(ratings.items()):
        print(f"  {k:<10} avg {sum(xs) / len(xs):.1f}   ({len(xs)} answers)")
    for k, v in rtags.most_common():
        print(f"  {v:>4}  {k}")
    print("\nTUTORIALS SHOWN")
    for k, v in tuts.most_common(15):
        print(f"  {k:<24} {v:>4}")
    if feedback:
        print("\nWRITTEN FEEDBACK")
        for pid, scr, txt in feedback:
            print(f"  [{pid[:6]} @ {scr}] {txt}")
    if csv_out:
        import csv
        with open(csv_out, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"\nper-tester table written to {csv_out}")
    print()

if __name__ == "__main__":
    main()
