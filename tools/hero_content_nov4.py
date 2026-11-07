"""Voice lines, Memories and profiles for the 4 November heroes (merges, never overwrites).
Run: python3 tools/hero_content_nov4.py && python3 tools/gen_voices.py"""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
C = "commander"
VOICE = {
 "angela": {"pitch": 1.08, "rate": 165, "lines": {
  "greet": ["天はあなたを守れと命じたわ。…志願したのは私だけど。", "Heaven ordered me to guard you. ...I volunteered, actually."],
  "tap": ["羽に触れないで！…くすぐったいの。", "Don't touch my wings! ...It tickles."],
  "bond": ["この翼は、あなたの空を守るためにあるの。", "These wings exist to guard your sky."],
  "skill": ["熾天使の審判を！", "Seraph's Verdict!"],
  "win": ["光は、いつも正しい側に。", "The light is always on the right side."],
  "summon": ["熾天のヴァルキリー、アンジェラ。あなたの剣となりましょう。", "Angela, Seraphic Valkyrie. I shall be your sword."]}},
 "kara": {"pitch": 1.0, "rate": 155, "lines": {
  "greet": ["死神があなたの隣を歩いているわ。幸運ね、気に入られてるもの。", "Death walks beside you. Lucky you — she likes you."],
  "tap": ["鎌に気をつけて。魂ごと刈り取っちゃうわよ。", "Careful with the scythes. I might reap your soul too."],
  "bond": ["何千の魂を刈ってきたけど、あなたの魂だけは守りたいの。", "I've reaped thousands of souls. Yours is the only one I want to protect."],
  "skill": ["不死鳥の収穫！", "Phoenix Harvest!"],
  "win": ["灰から蘇るのは、私たちだけ。", "Only we rise from the ashes."],
  "summon": ["不死鳥の死神、カーラ。あなたの命、預かるわ。", "Kara, the Phoenix Reaper. I'll take care of your life."]}},
 "mei": {"pitch": 1.14, "rate": 180, "lines": {
  "greet": ["耳を見ないで。剣を見て。そっちの方が鋭いから。", "Don't stare at the ears. Stare at the sword. It's sharper."],
  "tap": ["ちょっと！うさ耳は飾りじゃないんだから！", "Hey! The bunny ears aren't just for show!"],
  "bond": ["百本の剣より、あなた一人を守りたい。", "I'd rather protect you than a hundred swords."],
  "skill": ["紅月斬！", "Crimson Moon Slash!"],
  "win": ["ぴょんっと勝利！…今の、忘れて。", "Hop to victory! ...Forget I said that."],
  "summon": ["紅刃のバニー、メイ！剣も耳も、全部あなたのもの！", "Mei, the Crimson Blade Bunny! My swords and ears are all yours!"]}},
 "ninger": {"pitch": 1.22, "rate": 190, "lines": {
  "greet": ["私のコイン全部が言ってるわ、今日はいい日になるって！", "Every coin I own says you'll have a lucky day!"],
  "tap": ["きゃっ、金貨が落ちちゃう！", "Kya, my gold coins will fall!"],
  "bond": ["宝箱いっぱいの金より、あなたの笑顔の方が価値があるわ。", "Your smile is worth more than a chest full of gold."],
  "skill": ["黄金の幸運の雨！", "Rain of Golden Fortune!"],
  "win": ["勝利の配当、山分けね！", "Let's split the victory dividends!"],
  "summon": ["千金の姫、寧兒です！幸運をお届けします！", "Ning Er, Princess of a Thousand Coins! Delivering good luck!"]}},
 "spimei": {"pitch": 1.1, "rate": 175, "lines": {
  "greet": ["ドローン起動。翼起動。心も起動…困ったことにね。", "Drones online. Wings online. Heart... also online, unfortunately."],
  "tap": ["警告：接触を検知。…嫌じゃない、けど。", "Warning: contact detected. ...Not unpleasant, though."],
  "bond": ["私の全回路が、あなたのことで熱くなるの。", "Every circuit I have heats up because of you."],
  "skill": ["深紅のドローン群、発進！", "Scarlet Drone Swarm, launch!"],
  "win": ["任務完了。損害ゼロ。…褒めて？", "Mission complete. Zero damage. ...Praise me?"],
  "summon": ["深紅の蜘蛛機関、スパイメイ。あなたの命令を待ってる。", "Spimei, Scarlet Spider Engine. Awaiting your orders."]}},
}
def ep(t, *lines):
    return {"title": t, "lines": [list(l) for l in lines]}
MEM = {
 "angela": [
  ep("Feathers on the Floor", ["angela", "Don't laugh. I'm molting. Angels molt."], [C, "There are feathers everywhere."], ["angela", "...Keep one. It's lucky. Probably."]),
  ep("The Volunteer", ["angela", "Heaven asked for a guardian. Nobody else raised their hand."], [C, "So you did?"], ["angela", "I raised both hands. And my wings. ...I wanted it to be me."]),
  ep("Golden Wings", ["angela", "My wings turned gold today. That only happens when an angel finds where she belongs."], [C, "And where is that?"], ["angela", "Right here. Beside you. Don't make me say it twice."])],
 "kara": [
  ep("The Reaper's Tea", ["kara", "Even Death takes tea breaks. Sit."], [C, "Is this... safe?"], ["kara", "Perfectly. I only reap people I dislike. Drink up."]),
  ep("Phoenix Feathers", ["kara", "The birds follow me because I keep bringing them back. Every time they burn, they rise."], [C, "Like you."], ["kara", "...You noticed. Hm. Nobody notices."]),
  ep("A Soul Worth Keeping", ["kara", "I've seen every soul's ending. Yours is the only one I refuse to look at."], [C, "Why?"], ["kara", "Because I want to be surprised. I want to spend all of it with you."])],
 "mei": [
  ep("The Sword Rack", ["mei", "Every blade on this rack has a name. This one is 'Breakfast'."], [C, "Why Breakfast?"], ["mei", "Because I cut toast with it. Don't judge me."]),
  ep("About the Ears", ["mei", "Everyone asks if they're real. They are. They twitch when I'm nervous."], [C, "They're twitching now."], ["mei", "...Shut up. Look at the sword."]),
  ep("Red Moon", ["mei", "My blade burns red when I fight for someone I love."], [C, "It's glowing right now."], ["mei", "...I know. It's been glowing since you walked in. Idiot."])],
 "ninger": [
  ep("Counting Coins", ["ninger", "Nine thousand nine hundred ninety-nine... oh! You made me lose count!"], [C, "Sorry."], ["ninger", "Then you owe me one coin. Or... one smile. Smiles are worth more."]),
  ep("The Treasure Chest", ["ninger", "This chest holds my most precious treasure."], [C, "Gold?"], ["ninger", "A pressed flower you gave me. ...Don't laugh! It's priceless!"]),
  ep("A Thousand Coins", ["ninger", "I'd trade every coin I own for one more day like today."], [C, "You don't have to trade anything."], ["ninger", "...Then I'm the richest princess in the world."])],
 "spimei": [
  ep("Maintenance Day", ["spimei", "My drones need oiling. Hold this wrench. No, the other end."], [C, "Like this?"], ["spimei", "Efficient. You'd make a good engineer. ...Or a good partner."]),
  ep("Error: Heart", ["spimei", "My diagnostics show an anomaly. Heart rate elevated near you."], [C, "Is that bad?"], ["spimei", "Unknown. I've decided not to fix it."]),
  ep("Scarlet Wings", ["spimei", "I built these wings to fly away from everyone."], [C, "And now?"], ["spimei", "Now I use them to fly back to you. Faster than any drone."])],
}
PROFILES = {
 "angela": {"birthday": "12-08", "height": 172, "likes": "Sunrise, feathers, honest people", "dislikes": "Lies, cages", "hobby": "Polishing her sword", "cv": "TBA"},
 "kara": {"birthday": "10-02", "height": 170, "likes": "Black tea, phoenixes, quiet graveyards", "dislikes": "Wasted lives", "hobby": "Caring for her phoenix birds", "cv": "TBA"},
 "mei": {"birthday": "04-14", "height": 163, "likes": "Swords, carrots, moonlit nights", "dislikes": "Ear jokes", "hobby": "Naming her blades", "cv": "TBA"},
 "ninger": {"birthday": "02-08", "height": 158, "likes": "Gold, treasure maps, good luck charms", "dislikes": "Debt", "hobby": "Counting coins", "cv": "TBA"},
 "spimei": {"birthday": "07-30", "height": 165, "likes": "Machines, red paint, efficiency", "dislikes": "Rust, small talk", "hobby": "Building drones", "cv": "TBA"},
}
for name, data in [('voice_lines.json', VOICE), ('memories.json', MEM), ('profiles.json', PROFILES)]:
    path = os.path.join(ROOT, 'data', name)
    cur = json.load(open(path, encoding='utf-8'))
    for k, v in data.items():
        cur.setdefault(k, v)
    json.dump(cur, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print("content merged")
