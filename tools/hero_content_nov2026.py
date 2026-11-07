"""Voice lines + Memories for the November 2026 heroes.
Merges into data/voice_lines.json and data/memories.json WITHOUT overwriting existing entries.
Run: python3 tools/hero_content_nov2026.py && python3 tools/gen_voices.py abadonia aqua atalanta kali rubby schylua siv vexira zennyo sven
"""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
C = "commander"

VOICE = {
    "abadonia": {"pitch": 1.02, "rate": 160, "lines": {
        "greet": ["獅子の女王が、あなたを待っていたわ。", "The Lion Queen has been waiting for you."],
        "tap": ["無礼者…でも、あなたなら許してあげる。", "How rude... but for you, I'll allow it."],
        "bond": ["この盾は、あなたの心も守るためにあるの。", "This shield exists to protect your heart as well."],
        "skill": ["獅子王の突撃、受けてみなさい！", "Face the Lion Sovereign's charge!"],
        "win": ["王の前に、敵はなし。", "No enemy stands before a queen."],
        "summon": ["深淵の獅子女王、アバドニア。我が軍門に迎えましょう。", "Abadonia, Abyssal Lion Queen. I welcome you to my legion."]}},
    "aqua": {"pitch": 1.2, "rate": 185, "lines": {
        "greet": ["おかえりなさい！聖杯のお水、飲みますか？", "Welcome back! Want a sip from the holy chalice?"],
        "tap": ["ひゃっ！お水がこぼれちゃいます！", "Hya! The water's going to spill!"],
        "bond": ["あなたの喉が渇かないように、ずっとそばにいます。", "I'll stay by your side so you'll never go thirsty."],
        "skill": ["潮の聖杯よ、みんなを癒して！", "Chalice of the tides, heal everyone!"],
        "win": ["みんな無事でよかったです〜！", "I'm so glad everyone's okay~!"],
        "summon": ["潮の聖杯を運ぶ者、アクアです！よろしくお願いします！", "I'm Aqua, bearer of the tidal chalice! Nice to meet you!"]}},
    "atalanta": {"pitch": 1.16, "rate": 215, "lines": {
        "greet": ["遅いよ、司令官！私はもう三周走ったんだから！", "You're slow, Commander! I've already run three laps!"],
        "tap": ["捕まえてみなよ！…あ、捕まっちゃった。", "Catch me if you can! ...Ah, you caught me."],
        "bond": ["どんなに速く走っても、あなたの所に戻ってくるの。", "No matter how fast I run, I always come back to you."],
        "skill": ["雷鳴の一歩！", "Thunderstep!"],
        "win": ["私の勝ち！誰も追いつけないよ！", "I win! No one can keep up!"],
        "summon": ["雷の狩人アタランテ！最速で駆けつけたよ！", "Atalanta the thunder huntress! I got here at top speed!"]}},
    "kali": {"pitch": 1.06, "rate": 160, "lines": {
        "greet": ["百本の刀が、今日もあなたを守ります。", "A hundred blades will guard you again today."],
        "tap": ["…刀に触れないでください。指が切れますよ。", "...Please don't touch the swords. You'll cut your fingers."],
        "bond": ["百本の刀より、あなた一人のほうが重いのです。", "You alone weigh more to me than a hundred blades."],
        "skill": ["百刀の雨！", "Hundred Blade Rain!"],
        "win": ["刃は鞘に。戦いは終わりました。", "Blades to their sheaths. The battle is over."],
        "summon": ["百刀の聖女、カーリー。あなたの剣となりましょう。", "Kali, Saint of a Hundred Blades. I shall be your sword."]}},
    "zennyo": {"pitch": 1.12, "rate": 175, "lines": {
        "greet": ["竜王の娘を待たせるなんて…まあ、今日は許します。", "Keeping the Dragon King's daughter waiting... I'll forgive you today."],
        "tap": ["こら、ちびドラゴンたちが真似しちゃうでしょ。", "Hey, the little dragons will copy you!"],
        "bond": ["この子たちも、あなたを家族だと思ってるわ。", "These little ones think of you as family too."],
        "skill": ["竜王の行進、焼き尽くせ！", "Dragon King's parade, burn them!"],
        "win": ["ふふ、竜の炎に敵はいないわ。", "Fufu, nothing survives dragon fire."],
        "summon": ["竜王の娘、善女竜王。小さな竜たちと一緒にお仕えします。", "Zennyo Ryuo, daughter of the Dragon King. My little dragons and I are at your service."]}},
    "rubby": {"pitch": 1.1, "rate": 170, "lines": {
        "greet": ["あら、司令官。今日は何を爆発させましょうか？", "Oh, Commander. What shall we blow up today?"],
        "tap": ["ふふ、触ると…ドカン、ですよ？", "Fufu, if you touch me... boom, you know?"],
        "bond": ["あなたといると、心臓が爆発しそう。", "Being with you makes my heart want to explode."],
        "skill": ["ビッグバン・バラード！", "Big Bang Ballad!"],
        "win": ["綺麗な花火だったでしょう？", "Wasn't that a pretty firework?"],
        "summon": ["爆弾令嬢ルビー。素敵な爆発をお届けします。", "Rubby, the Bomb Belle. I deliver lovely explosions."]}},
    "schylua": {"pitch": 1.08, "rate": 165, "lines": {
        "greet": ["…凍える風の中、あなたの声だけが温かい。", "...In the freezing wind, only your voice is warm."],
        "tap": ["鎌に近づかないで。凍っちゃうから。", "Don't get near the scythe. You'll freeze."],
        "bond": ["氷の鎌は、あなたを守るためだけに振るう。", "I swing this ice scythe only to protect you."],
        "skill": ["氷河の刈り取り。", "Glacial reap."],
        "win": ["すべて、凍りついた。", "Everything has frozen."],
        "summon": ["氷の死神、シュルア。命を刈る…でも、あなたは別。", "Schylua, the Frost Reaper. I reap lives... but not yours."]}},
    "vexira": {"pitch": 1.1, "rate": 170, "lines": {
        "greet": ["あら〜、司令官。今夜も私に会いに来たの？", "Ara~ Commander. Did you come to see me again tonight?"],
        "tap": ["ふふっ、くすぐったい。もっと…？", "Fufu, that tickles. More...?"],
        "bond": ["魅了するつもりが…私が魅了されちゃった。", "I meant to charm you... but you charmed me instead."],
        "skill": ["破滅の魅惑！", "Charm of Ruin!"],
        "win": ["みんな私に夢中ね。", "Everyone's crazy about me."],
        "summon": ["サキュバスのヴェクシラよ。あなたの夢にお邪魔するわ。", "I'm Vexira the succubus. I'll be visiting your dreams."]}},
    "siv": {"pitch": 1.2, "rate": 190, "lines": {
        "greet": ["し、司令官！ハンマーの準備はできてます！", "C-Commander! My hammer is ready!"],
        "tap": ["わわっ、ハンマー落としちゃう！", "Wawa, I'm going to drop my hammer!"],
        "bond": ["重いハンマーも、あなたのためなら軽く感じます。", "Even this heavy hammer feels light when it's for you."],
        "skill": ["サンダー・タップ！", "Thunder tap!"],
        "win": ["や、やりました！ちゃんと当たりました！", "I-I did it! I actually hit them!"],
        "summon": ["雷槌の乙女、シヴです！が、頑張ります！", "I'm Siv, the Thunder Hammer Maiden! I'll do my best!"]}},
    "sven": {"pitch": 1.0, "rate": 150, "lines": {
        "greet": ["…戻ったか。剣の手入れは済ませておいた。", "...You're back. I've already polished my sword."],
        "tap": ["何だ。…暇なら、隣に座れ。", "What is it. ...If you're free, sit next to me."],
        "bond": ["旅の終わりを探していた。それは、ここだったのかもしれない。", "I was looking for the end of my journey. Maybe it was here."],
        "skill": ["裂け、大剣よ。", "Cleave, greatsword."],
        "win": ["…悪くない戦いだった。", "...Not a bad fight."],
        "summon": ["流浪の大剣士、スヴェン。剣を貸そう。", "Sven, wandering greatsword. I'll lend you my blade."]}},
}

def ep(t, *lines):
    return {"title": t, "lines": [list(l) for l in lines]}

MEM = {
 "abadonia": [
  ep("The Lion's Stable",
     ["abadonia", "Do not approach my lion carelessly. He has eaten knights."], [C, "He's purring at me."],
     ["abadonia", "...Traitor. He has never purred for anyone but me."], ["abadonia", "Perhaps he senses what I sense. Hmph."]),
  ep("A Queen's Armor",
     ["abadonia", "Help me remove this armor. The clasp is stuck."], [C, "It's heavy."],
     ["abadonia", "A queen carries the weight of her people. Every day."], [C, "Then let me carry some of it."],
     ["abadonia", "...You say the most foolish, wonderful things."]),
  ep("Crown and Oath",
     ["abadonia", "I have ruled the abyss for an age. I swore never to bow."], ["abadonia", "So I will not bow. I will offer my hand instead."],
     [C, "I'll take it."], ["abadonia", "Then from today, my kingdom has two rulers. Do not disappoint me, my consort."]),
 ],
 "aqua": [
  ep("Spilled Water",
     ["aqua", "Ah! I spilled the holy water on your map..."], [C, "It's okay, it'll dry."],
     ["aqua", "You're too kind! Here, have a drink to make up for it!"], [C, "...It tastes sweet."], ["aqua", "That's my blessing! Ehehe."]),
  ep("Rain Dance",
     ["aqua", "It's raining! Come dance with me!"], [C, "We'll get soaked."],
     ["aqua", "That's the fun part! Water is life, and you're... um... my life?"], ["aqua", "W-wait, forget I said that!"]),
  ep("The Bottomless Chalice",
     ["aqua", "They say my chalice never runs dry. But my heart did, for a long time."], ["aqua", "Then you came, and it overflowed."],
     [C, "I'm glad."], ["aqua", "Let me fill your cup for the rest of our lives, okay?"]),
 ],
 "atalanta": [
  ep("The Race",
     ["atalanta", "Race me to the tree! Loser buys dinner!"], [C, "You're made of lightning. That's unfair."],
     ["atalanta", "Fine, I'll give you a ten-second head start! ...Go! ...Caught you!"], [C, "I'm buying dinner, aren't I?"]),
  ep("Static",
     ["atalanta", "Ouch! Sorry, I shocked you again."], [C, "It's fine. It's kind of nice."],
     ["atalanta", "Nice? Weirdo! ...My lightning only sparks like that around you, you know."]),
  ep("Standing Still",
     ["atalanta", "I've never stopped running. Not once, my whole life."], ["atalanta", "But right now... I just want to stand still. Here, with you."],
     [C, "Then stay."], ["atalanta", "Okay. For you, I'll be the slowest girl in the world."]),
 ],
 "kali": [
  ep("Counting Swords",
     ["kali", "Ninety-eight, ninety-nine... one is missing."], [C, "This one? I found it by the river."],
     ["kali", "...Thank you. That sword was my mother's."], ["kali", "You carried it back all this way? You are a strange person."]),
  ep("Lesson of the Blade",
     ["kali", "Hold the sword like this. Gently. Like holding a bird."], [C, "Like this?"],
     ["kali", "...Yes. Your hands are warm. Don't let go yet."]),
  ep("The Hundred and First",
     ["kali", "A hundred blades, and I trusted none of them more than my own two hands."], ["kali", "Now I have a hundred and one. You are my newest blade."],
     [C, "And your most loyal one."], ["kali", "Then let us never be sheathed apart."]),
 ],
 "zennyo": [
  ep("Dragon Daycare",
     ["zennyo", "Can you watch my little dragons for an hour?"], [C, "Sure. How hard can it be?"],
     ["zennyo", "...Why is the tent on fire?"], [C, "They wanted to play."], ["zennyo", "Fufu. They really do like you."]),
  ep("Princess Lessons",
     ["zennyo", "Father taught me to rule with fire and fear."], [C, "And what do you think?"],
     ["zennyo", "I think... I'd rather rule with warmth. Like the way you lead us."]),
  ep("Dragon's Promise",
     ["zennyo", "Dragons mate for life. Did you know that?"], [C, "I didn't."],
     ["zennyo", "Now you do. ...Don't make me say it more plainly, Commander."], ["zennyo", "My dragons already call you 'papa', you know."]),
 ],
 "rubby": [
  ep("Bomb Friends",
     ["rubby", "Meet my friends. This is Boom, and this is Kaboom."], [C, "They're... smiling."],
     ["rubby", "They're happy to meet you. Don't worry, they only explode when I ask nicely."]),
  ep("Quiet Night",
     ["rubby", "Everyone thinks I love loud things. Explosions, fireworks..."], ["rubby", "But I love quiet nights like this. With you."],
     [C, "Me too."]),
  ep("The Biggest Firework",
     ["rubby", "I saved my biggest firework for a special day."], [C, "What day is that?"],
     ["rubby", "Today. Look up!"], ["rubby", "...It spells your name. Do you like it?"]),
 ],
 "schylua": [
  ep("Frozen Breath",
     ["schylua", "Don't stand so close. You'll catch a cold."], [C, "I'll risk it."],
     ["schylua", "...Foolish. Here, take my scarf. It's the only warm thing I own."]),
  ep("The Reaper's List",
     ["schylua", "Death gave me a list of souls to reap."], [C, "Am I on it?"],
     ["schylua", "You were. I tore that page out."]),
  ep("Thaw",
     ["schylua", "My body is made of ice. Holding me will hurt."], [C, "I don't care."],
     ["schylua", "...Strange. Your arms are warm, and I'm not melting."], ["schylua", "Maybe I was waiting for someone like you to thaw me."]),
 ],
 "vexira": [
  ep("Dream Visit",
     ["vexira", "Ara~ Did you enjoy my visit in your dream last night?"], [C, "I don't remember anything."],
     ["vexira", "Fufu, that's how it should be. Some secrets are sweeter kept."]),
  ep("Imp Trouble",
     ["vexira", "My imps stole your boots again. Sorry~"], [C, "Why do they keep doing that?"],
     ["vexira", "They want you to stay longer. ...They take after me."]),
  ep("Real Feelings",
     ["vexira", "A succubus lives on desire. Love is supposed to be a game."], ["vexira", "So why does this hurt so much when you're away?"],
     [C, "Maybe it's not a game anymore."], ["vexira", "...Then I lose. Happily."]),
 ],
 "siv": [
  ep("Hammer Practice",
     ["siv", "Watch me! Hyaa!"], [C, "You hit the target!"],
     ["siv", "I did?! I always miss! It must be because you're watching!"]),
  ep("Too Heavy",
     ["siv", "This hammer is too heavy for me. Everyone says so."], [C, "But you carry it every day."],
     ["siv", "...Because I want to protect people. Like you."]),
  ep("Lightning Strikes Twice",
     ["siv", "They say lightning never strikes the same place twice."], ["siv", "But my heart keeps getting struck. Every time I see you."],
     [C, "That's a nice way to say it."], ["siv", "Eh?! Did I say that out loud?!"]),
 ],
 "sven": [
  ep("Campfire",
     ["sven", "..."], [C, "You don't talk much."], ["sven", "Words are cheap. Fire is warm. Sit."], [C, "Thanks."],
     ["sven", "...You're welcome."]),
  ep("The Broken Hilt",
     ["sven", "This sword belonged to my old master. He died protecting me."], [C, "I'm sorry."],
     ["sven", "Don't be. He'd be glad I found someone worth protecting too."]),
  ep("Wanderer's Rest",
     ["sven", "I've walked across six kingdoms looking for a place to belong."], ["sven", "I think I can stop walking now."],
     [C, "Welcome home, Sven."], ["sven", "...Home. I like the sound of that."]),
 ],
}

for name, data in [('voice_lines.json', VOICE), ('memories.json', MEM)]:
    path = os.path.join(ROOT, 'data', name)
    cur = json.load(open(path, encoding='utf-8'))
    added = 0
    for k, v in data.items():
        if k not in cur:
            cur[k] = v
            added += 1
    json.dump(cur, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(name, 'added', added, 'total', len(cur))
