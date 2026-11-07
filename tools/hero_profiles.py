"""Writes data/profiles.json (edit freely). Existing entries are kept."""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
P = {
 "shina":    ["08-14", 158, "Spicy food, sparring, shiny scales", "Being treated like a kid", "Polishing her horns"],
 "xylia":    ["11-03", 171, "Blueprints, dark tea, quiet nights", "Messy rooms", "Redesigning castles"],
 "micca":    ["04-01", 149, "Pranks, sweets, surprises", "Boring days", "Collecting odd trinkets"],
 "cthollia": ["06-21", 166, "Deep water, lullabies, seafood (ironically)", "Bright sunlight", "Singing to the tide"],
 "valeria":  ["12-24", 172, "Snowfall, hot cocoa, swordplay", "Hot summers", "Ice sculpting"],
 "eropatra": ["07-23", 170, "Gold, perfume, being admired", "Sand in her shoes", "Collecting jewelry"],
 "furu":     ["03-03", 155, "Prayer, warm bread, children", "Arguments", "Tending a herb garden"],
 "glytta":   ["05-05", 157, "Dancing, festivals, glitter", "Standing still", "Choreography"],
 "hyeonxa":  ["10-31", 168, "Herbal brews, chess, silence", "Fools", "Brewing antidotes"],
 "scylla":   ["09-09", 163, "The sea at night, quiet company", "Crowds", "Watching the tide"],
 "lumeira":  ["04-21", 154, "Butterflies, naps, starlight", "Loud noises", "Dream journaling"],
 "gemora":   ["02-29", 160, "Data, star maps, new words", "Rain (static!)", "Studying human customs"],
 "fidelia":  ["06-01", 164, "Training, honor, the Commander's safety", "Cowardice", "Shield polishing"],
 "lucidria": ["01-15", 175, "Old ruins, flowers, stillness", "Chatter", "Pressing flowers"],
 "eurnipha": ["11-30", 174, "Warmth, embraces, midnight snacks", "Being alone", "Knitting (badly)"],
 "rumi":     ["10-13", 152, "Money, mochi, exorcism gigs", "Free work", "Counting coins"],
 "mora":     ["01-01", 162, "Clocks, sunsets, long stories", "Being rushed", "Keeping a diary"],
 "abadonia": ["08-08", 178, "Her lion, loyalty, red wine", "Disrespect", "Grooming her lion"],
 "aqua":     ["07-07", 156, "Clean water, rain, tea parties", "Droughts", "Polishing her chalice"],
 "atalanta": ["05-20", 165, "Running, thunderstorms, races", "Slowpokes", "Morning sprints"],
 "kali":     ["03-15", 167, "Blades, calligraphy, discipline", "Rust", "Sword care"],
 "rubby":    ["12-31", 161, "Fireworks, her bomb friends, cake", "Damp gunpowder", "Making fireworks"],
 "schylua":  ["02-02", 159, "Snow, silence, warm scarves", "Hot weather", "Ice fishing"],
 "vexira":   ["02-14", 163, "Sweets, mischief, the Commander", "Holy water", "Visiting dreams"],
 "siv":      ["09-21", 150, "Thunder, big hammers, praise", "Missing her target", "Hammer practice"],
 "sven":     ["11-11", 176, "Campfires, quiet roads, stew", "Small talk", "Whittling wood"],
 "zennyo":   ["06-15", 166, "Her little dragons, hot springs", "Cold rain", "Dragon babysitting"],
}
path = os.path.join(ROOT, 'data', 'profiles.json')
cur = json.load(open(path, encoding='utf-8')) if os.path.exists(path) else {}
for k, v in P.items():
    cur.setdefault(k, {"birthday": v[0], "height": v[1], "likes": v[2], "dislikes": v[3], "hobby": v[4], "cv": "TBA"})
json.dump(cur, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(len(cur), "profiles")
