#!/bin/zsh
# UI smoke test: opens every screen and plays every battle mode to its result + CONTINUE.
# Fails on script errors or when a screen gets stuck. Usage: zsh tools/smoke.sh
cd "$(dirname "$0")/.."
GODOT=/Users/apple/Downloads/Godot.app/Contents/MacOS/Godot
SAVE=~/Library/Application\ Support/Godot/app_userdata/Euphoria\ Online/euphoria_v2_save.json
OUT=$(mktemp -d)
rm -f "$SAVE"
SCREENS="lobby,heroes,hero_detail:id=shina,formation,story,gacha,shop,shop:tab=market,shop:tab=friend_point,shop:tab=arena_coin,bag,quests,mail,arena,tower,settings,event,guild,friends,dungeon,pass,garden,gallery,expedition,minigame,worldboss,festival,hunt,hunt:shop=1,rift,room,room:loc=room1,bestiary,date,date:tab=album,wardrobe,photo,forge,forge:tab=temper,forge:tab=fuse,forge:tab=salvage"
BATTLES="story:select=5,battle:mode=story&stage=5,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,close,expect:story,worldboss,battle:mode=wboss,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:worldboss,hunt,battle:mode=hunt&hunt=canopy&diff=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:hunt,riftstart,rift,battle:mode=rift,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:rift,dungeon,battle:mode=dungeon&dungeon=gold&diff=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:dungeon,tower,battle:mode=tower&floor=1,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:tower,hero_detail:id=shina,battle:mode=trial&hero=shina&tier=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:hero_detail,arena,battle:mode=arena&opp=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:arena,guild,battle:mode=raid,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:guild,event,battle:mode=event&stage=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:event,story,battle:mode=hard&stage=0,skipbattle,wait,wait,wait,wait,wait,wait,wait,wait,wait,wait,pressok,wait,expect:story,spawngear:8,forge:tab=temper,close,press:TEMPER  ,wait,press:KEEP CURRENT,wait,press:TEMPER  ,wait,press:TAKE NEW,wait,expect:forge,lobby,news,close"
STEPS="close,boost,game:add_player_exp|2000000,close,${SCREENS//,/,close,},close,$BATTLES"
LOG=$("$GODOT" --path . -s res://tools/shot_runner.gd -- "$OUT" "$STEPS" 12 2>&1)
rm -rf "$OUT"; rm -f "$SAVE"
ERR=$(echo "$LOG" | grep -E "SCRIPT ERROR|Invalid call|Nonexistent function|Invalid access|STUCK" | sort | uniq -c)
echo "$LOG" | grep -c "^SHOT" | xargs echo "steps run:"
echo "$LOG" | grep "OK screen"
if [ -n "$ERR" ]; then echo "SMOKE: FAIL"; echo "$ERR"; exit 1; fi
echo "SMOKE: PASS"
