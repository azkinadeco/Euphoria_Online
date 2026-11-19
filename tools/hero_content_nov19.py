"""Voice lines, Memories and profiles for the 19 November 2026 heroes.
Merges into data/voice_lines.json, data/memories.json and data/profiles.json WITHOUT overwriting existing entries.
Run: python3 tools/hero_content_nov19.py && python3 tools/gen_voices.py aura fuji kyra sharas toka tora tsundae vila yumi
"""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
C = "commander"

def V(pitch, rate, greet, tap, bond, skill, win, summon, hurt, ko):
    return {"pitch": pitch, "rate": rate, "lines": {"greet": greet, "tap": tap, "bond": bond, "skill": skill, "win": win,
                                                    "summon": summon, "hurt": hurt, "ko": ko}}

VOICE = {
    "aura": V(1.16, 180, ["私の輪が、矢より先にあなたを見つけたの。", "My rings found you before my arrows did. ...Lucky you."],
              ["ひゃっ…！輪に触らないで、くすぐったいの。", "Hya...! Don't touch the rings, it tickles."],
              ["この心は、もう射抜かれちゃったみたい。", "Looks like my heart is the one that got shot."],
              ["星弓・リングボレー！", "Starbow Ring Volley!"], ["全部命中。…当然よ。", "Every arrow hit. ...Of course."],
              ["奥義の射手、アウラ。あなたの的になってあげる。", "Aura, the arcane archer. I'll let you be my target."],
              ["きゃっ！", "Kya!"], ["輪が…消えちゃう…", "My rings... are fading..."]),
    "fuji": V(1.04, 165, ["司令官、検診の時間ですよ。じっとしてて。", "Time for your check-up, Commander. Sit still~"],
              ["こら、注射はまだですよ？", "Hey now, it's not time for the injection yet."],
              ["あなたの心音、私が一番知ってるの。", "I know your heartbeat better than anyone."],
              ["スカーレット・インジェクション！", "Scarlet Injection!"], ["みんな健康、問題なしです。", "Everyone's healthy. No problems."],
              ["緋色の看護師、フジです。お大事にね。", "I'm Fuji, the scarlet nurse. Take care of yourself."],
              ["痛っ…", "Ow..."], ["ごめんね…もう、診てあげられない…", "Sorry... I can't treat you anymore..."]),
    "kyra": V(1.0, 160, ["じろじろ見ないで。…少しならいいけど。", "Don't stare. ...Fine. Stare a little."],
              ["角に触るな！…熱くないから。", "Don't touch the horns! ...They're not hot."],
              ["この翡翠の炎、あなたのためだけに燃えてるの。", "This jade flame only burns for you."],
              ["翡翠炎・重力崩し！", "Jadeflame Gravity!"], ["跪け。…あ、あなたは立ってていい。", "Kneel. ...Ah, you can stay standing."],
              ["翡翠炎の鬼、キラ。…よろしく。", "Kyra, the jadeflame oni. ...Nice to meet you."],
              ["ぐっ…！", "Ngh...!"], ["炎が…消える…", "My flame... is dying..."]),
    "sharas": V(1.14, 205, ["ブンブン！チェーンソーも私も温まってるよ！", "Rev, rev! The chainsaws are warm and so am I."],
              ["危ないってば！刃が回ってるの！", "It's dangerous! The blades are spinning!"],
              ["竜は宝を守るの。私の宝はあなた。", "Dragons guard their treasure. Mine is you."],
              ["ツインチェーンソー・インフェルノ！", "Twin Chainsaw Inferno!"], ["切り刻んじゃった！楽しかった！", "Chopped them all up! That was fun!"],
              ["チェーンソーの竜娘、シャラス！燃えていこう！", "Sharas, the chainsaw dragoness! Let's burn it up!"],
              ["いったぁ！", "Owww!"], ["エンジンが…止まっちゃう…", "My engine... is stalling..."]),
    "toka": V(1.22, 215, ["スパーリングする？手加減してあげる！…たぶん！", "Ready for a sparring match? I'll go easy on you! ...Maybe!"],
              ["わっ！ガード、ガード！", "Whoa! Guard, guard!"],
              ["あなたの笑顔には、いつもガードが下がっちゃう。", "My guard always drops when you smile."],
              ["ブレイジング・アッパー！", "Blazing Uppercut!"], ["KO勝ち！いぇーい！", "Win by KO! Yay!"],
              ["燃える拳のボクサー、トカ！一緒に戦おう！", "Toka, the blazing fist boxer! Let's fight together!"],
              ["ぐはっ！", "Guhh!"], ["ダウン…テンカウント…", "Down... ten count..."]),
    "tora": V(1.06, 170, ["柔らかさも武器。翡翠の竜もね。", "Flexibility is a weapon. So is a jade dragon."],
              ["ふふ、足、どこまで上がるか見たい？", "Fufu, want to see how high my leg goes?"],
              ["翡翠の竜も、私も、あなたに頭を下げるわ。", "The jade dragon and I both bow to you."],
              ["翡翠竜・剣舞！", "Jade Dragon Split!"], ["舞は終わり。拍手は？", "The dance is over. Where's my applause?"],
              ["翡翠竜の剣舞姫、トラ。あなたのために舞うわ。", "Tora, the jade dragon sword dancer. I'll dance for you."],
              ["っ…！", "Tch...!"], ["舞が…止まる…", "My dance... is ending..."]),
    "tsundae": V(1.2, 195, ["べ、別にあなたに会いに来たわけじゃないんだから！", "I-it's not like I came here to see you! I was just passing by!"],
              ["さ、触らないでよ！…燃やすわよ！", "D-don't touch me! ...I'll burn you!"],
              ["…好き。今の、聞かなかったことにして！", "...I like you. Forget you heard that!"],
              ["アズール・フレイム！", "Azure Flame Burst!"], ["当然でしょ。…褒めてもいいのよ？", "Obviously. ...You can praise me, you know?"],
              ["蒼炎の令嬢、ツンデ。あ、あなたのためじゃないから！", "Tsundae, the azure flame heiress. I-it's not for your sake!"],
              ["ひゃっ！", "Hyah!"], ["ばか…最後まで…そばに…", "Idiot... stay with me... till the end..."]),
    "vila": V(1.12, 190, ["カメラに笑って、司令官〜。今ライブ中よ！", "Smile for the camera, Commander~ We're live!"],
              ["きゃっ、今の配信に映っちゃった〜", "Kya, that just went out on stream~"],
              ["カメラを止めても、あなたには見ててほしいの。", "Even when the camera's off, I want you watching me."],
              ["クリムゾン・ウィング・アンコール！", "Crimson Wing Encore!"], ["視聴者数、また最高記録〜！", "Viewer count hit a new record~!"],
              ["深紅の翼のアイドル、ヴィラよ。フォローしてね〜", "I'm Vila, the crimson wing idol. Follow me~"],
              ["いやんっ！", "Ahn!"], ["配信…終了…", "Stream... ending..."]),
    "yumi": V(1.26, 175, ["ユミとうさぎたちが見張り中。ぴょんぴょん。", "Yumi and the bunnies are on guard duty. Hop hop."],
              ["耳、引っ張っちゃだめ。…やさしくなら、いい。", "Don't pull the ears. ...Gently is okay."],
              ["ユミのハンマーは、あなたを守るためにあるの。", "Yumi's hammer is here to protect you."],
              ["バニーハンマー・クエイク！", "Bunny Hammer Quake!"], ["ぺしゃんこ。うさぎたちも喜んでる。", "Squashed flat. The bunnies are happy too."],
              ["ハンマーの番兎、ユミ。ぴょん。", "Yumi, the bunny hammer warden. Hop."],
              ["ぴゃっ！", "Pya!"], ["うさぎたち…にげて…", "Bunnies... run..."]),
}

def ep(t, *lines):
    return {"title": t, "lines": [list(l) for l in lines]}

MEM = {
    "aura": [ep("The Rings", ("aura", "These rings float around me all the time. People think they're a shield."), (C, "Aren't they?"),
                ("aura", "...They're more like a fence. I put them up so nobody gets close. You walked right through.")),
             ep("Missed Shot", ("aura", "I missed a target today. First time in years."), (C, "What distracted you?"),
                ("aura", "You waved at me. From across the field. ...Don't do that during practice. Do it after.")),
             ep("Open Ring", ("aura", "Look. One ring stays open now, all the time."), (C, "Why that one?"),
                ("aura", "It's the one facing you. So you can always come in."))],
    "fuji": [ep("Clinic Hours", ("fuji", "You're the only patient who visits when he's not sick."), (C, "I like the company."),
                ("fuji", "...Then I'll extend clinic hours. Just for you. Don't tell the others.")),
             ep("The Big Syringe", ("fuji", "Everyone's scared of my syringe. It's just medicine, you know."), (C, "It's taller than you."),
                ("fuji", "Bigger dose, bigger smile. ...You're smiling. See? It works.")),
             ep("Night Shift", ("fuji", "I stayed up all night watching over the wounded."), (C, "Then rest. I'll watch over you."),
                ("fuji", "...A nurse being cared for. How strange. How nice. Just ten minutes, then."))],
    "kyra": [ep("Horns", ("kyra", "Children used to run when they saw my horns."), (C, "I think they look cool."),
                ("kyra", "...Cool. Nobody has ever said that. Say it again. Quietly.")),
             ep("Jade Fire", ("kyra", "The jade fire on my leg flares when I'm upset."), (C, "It's calm right now."),
                ("kyra", "Because you're here. Annoying. You make it hard to stay angry.")),
             ep("Crouching", ("kyra", "I always crouch low. An oni waits, ready to spring."), (C, "What are you waiting for?"),
                ("kyra", "...For you to sit next to me. Took you long enough."))],
    "sharas": [ep("Two Chainsaws", ("sharas", "Why two chainsaws? Because one felt lonely!"), (C, "That's... a reason."),
                  ("sharas", "Everyone needs a partner. Even chainsaws. Even dragons. ...Even me.")),
               ep("Dragon Tail", ("sharas", "My tail wags when I'm happy. It's very embarrassing."), (C, "It's wagging now."),
                  ("sharas", "I KNOW. Stop looking at it! ...Okay, you can look a little.")),
               ep("The Hoard", ("sharas", "Dragons hoard treasure. I hoard snacks. And memories with you."), (C, "That's a good hoard."),
                  ("sharas", "The best one in the world. And nobody is allowed to touch it."))],
    "toka": [ep("Gloves", ("toka", "These gloves were my dad's. He was a champion."), (C, "You're a champion too."),
                ("toka", "Not yet! But with you in my corner... I think I'll get there.")),
             ep("Rematch", ("toka", "You dodged my punch! How?!"), (C, "I've watched you train a lot."),
                ("toka", "You were watching me?! ...That's cheating. A cute kind of cheating.")),
             ep("Corner Man", ("toka", "Every boxer needs someone in her corner."), (C, "I'll always be in yours."),
                ("toka", "Then I'll never stay down. Not once. Promise!"))],
    "tora": [ep("The Split", ("tora", "This pose? It's my warm-up. Don't look so surprised."), (C, "It looks painful."),
                ("tora", "Only the first thousand times. ...After that, it's just beautiful.")),
             ep("Jade Dragon", ("tora", "The little jade dragons follow me everywhere."), (C, "They're following me now."),
                ("tora", "They know who I like. Traitors. Adorable traitors.")),
             ep("Last Dance", ("tora", "A sword dancer's final dance is for one person only."), (C, "Who will you dance it for?"),
                ("tora", "Don't ask questions you already know the answer to, Commander."))],
    "tsundae": [ep("Sweets", ("tsundae", "I didn't buy these for you. They were on sale."), (C, "They're my favourite."),
                   ("tsundae", "...I know. I mean—I didn't know! Coincidence! Eat them!")),
                ep("Blue Flame", ("tsundae", "My fire turns blue when I'm calm. It's been blue a lot lately."), (C, "Why lately?"),
                   ("tsundae", "...Because someone keeps being nice to me. It's YOUR fault, idiot.")),
                ep("Honest Words", ("tsundae", "I'll say it once. Only once. Are you listening?"), (C, "I'm listening."),
                   ("tsundae", "I'm glad I met you. ...There. Now forget it. No, don't forget it."))],
    "vila": [ep("Live Stream", ("vila", "Chat asked who you are. I said you're my manager."), (C, "Am I?"),
                ("vila", "You manage my heart rate, so yes~")),
             ep("Wings Off-Camera", ("vila", "My wings look great on camera. Off camera they're heavy."), (C, "Let me help carry them."),
                ("vila", "...Nobody ever asked if they were heavy. Thank you. Really.")),
             ep("Camera Off", ("vila", "I turned the camera off. No filters tonight."), (C, "You look the same. Beautiful."),
                ("vila", "...That's the first comment I ever wanted to pin forever."))],
    "yumi": [ep("The Hammer", ("yumi", "Yumi's hammer is bigger than Yumi."), (C, "Isn't it heavy?"),
                ("yumi", "Very. But protecting everyone is heavier. The hammer helps.")),
             ep("Bunny Patrol", ("yumi", "The bunnies report: Commander is safe. Commander ate lunch. Commander smiled twice."), (C, "They're spying on me?"),
                ("yumi", "Guarding. Yumi asked them. ...Yumi wanted to know you were okay.")),
             ep("Ears", ("yumi", "Nobody touches Yumi's ears. Rule number one."), (C, "Then I won't."),
                ("yumi", "...Rule number one has an exception now. Only you. Gently."))],
}

PROFILES = {
    "aura": {"birthday": "02-14", "height": 166, "likes": "Starlit archery ranges, quiet libraries", "dislikes": "Crowds, being touched without warning", "hobby": "Polishing her arcane rings", "cv": "TBA"},
    "fuji": {"birthday": "05-12", "height": 165, "likes": "Clean bandages, warm tea, healthy patients", "dislikes": "People who skip check-ups", "hobby": "Collecting syringe charms", "cv": "TBA"},
    "kyra": {"birthday": "10-31", "height": 170, "likes": "Jade lanterns, rainy nights, being called cool", "dislikes": "People staring at her horns", "hobby": "Staring contests (undefeated)", "cv": "TBA"},
    "sharas": {"birthday": "08-08", "height": 172, "likes": "Engine oil, bonfires, snacks", "dislikes": "Blunt blades, boredom", "hobby": "Tuning her chainsaws", "cv": "TBA"},
    "toka": {"birthday": "07-07", "height": 156, "likes": "Sparring, spicy ramen, her dad's gloves", "dislikes": "Giving up, cold showers", "hobby": "Morning runs", "cv": "TBA"},
    "tora": {"birthday": "03-21", "height": 171, "likes": "Jade dragons, stretching, applause", "dislikes": "Stiff joints, rushed dances", "hobby": "Sword dancing at dawn", "cv": "TBA"},
    "tsundae": {"birthday": "01-22", "height": 168, "likes": "Sweets (secretly), blue fire, being praised", "dislikes": "Admitting she likes things", "hobby": "Baking (badly, she says)", "cv": "TBA"},
    "vila": {"birthday": "06-06", "height": 167, "likes": "Live streams, red lace, followers", "dislikes": "Bad lighting, trolls", "hobby": "Dance challenges", "cv": "TBA"},
    "yumi": {"birthday": "04-04", "height": 150, "likes": "Bunnies, carrots, her big hammer", "dislikes": "People pulling her ears", "hobby": "Bunny patrol", "cv": "TBA"},
}

for name, src in (("voice_lines", VOICE), ("memories", MEM), ("profiles", PROFILES)):
    p = os.path.join(ROOT, 'data', name + '.json')
    d = json.load(open(p, encoding='utf-8'))
    n = 0
    for k, v in src.items():
        if k not in d:
            d[k] = v; n += 1
    json.dump(d, open(p, 'w', encoding='utf-8'), indent=1)
    print(name, '+%d' % n)
