#!/bin/zsh
# Layout audit: opens every screen and popup at three canvas shapes and fails when a text or panel is cut
# off or pushed outside the window. Usage: zsh tools/audit.sh [quick]   (quick = default shape only)
# Findings: CLIP text cut without "…", CUT sticks out of a clipping parent, OFF outside the window,
# FLAT a scroll list squeezed to no height.
# (TRIM = long ellipsis and OVER = overlapping texts are printed but do not fail the run.)
cd "$(dirname "$0")/.."
GODOT=${GODOT:-/Users/apple/Downloads/Godot.app/Contents/MacOS/Godot}
DATA=~/Library/Application\ Support/Godot/app_userdata/Euphoria\ Online
PREP="novn,notips,boost,clear:60,gset:player.level|40,close"
SCREENS="lobby,close,heroes,formation,story,gacha,shop,bag,quests,mail,arena,arena:tab=RANKING,arena:tab=DEFENSE,tower,settings,dungeon,guild,friends,event,pass,garden,gallery,expedition,worldboss,hunt,rift,room,bestiary,date,wardrobe,forge,messenger,kitchen,training,festival,photo,detail:hero_detail|shina,minigame"
POPUPS="lobby,close,cur:_open_menu,close,cur:_open_profile,close,cur:_open_fortune,close,cur:_pick_scene,close,board,close,schedule,close,news,close,call:show_login_calendar,close,call:show_how_to_play,close,heroes,cur:_codex,close,gacha,cur:_show_wishlist,close,cur:_show_history,close,cur:_show_rates,close,formation,cur:_show_all_tips,close,cur:_show_links,close,cur:_pick_tactic,close,cur:_power_up,close,settings,cur:_show_backups,close,cur:_show_guides,close,story,cur:_archive,close,cur:_interludes,close,garden,cur:_pick_residents,close,room,cur:_pick_hero,close,hero_detail:id=shina&tab=UPGRADE,hero_detail:id=shina&tab=GEAR,hero_detail:id=shina&tab=OUTFITS,hero_detail:id=shina&tab=BOND,formation:mode=story&stage=5"
FAIL=0
run() {  # name, godot args, first step
  local OUT=$(mktemp -d)
  rm -f "$DATA/euphoria_v2_save.json"; rm -rf "$DATA/backups"; rm -f "$DATA/playtest_log.json"
  local LOG=$(AUDIT=1 "$GODOT" ${=2} --path . -s res://tools/shot_runner.gd -- "$OUT" "$3$PREP,$SCREENS,close,$POPUPS" 16 2>&1)
  rm -rf "$OUT"; rm -f "$DATA/euphoria_v2_save.json"; rm -rf "$DATA/backups"; rm -f "$DATA/playtest_log.json"
  # steps before the first screen are still on the title screen while the scale changes: not layout bugs
  local BAD=$(echo "$LOG" | grep -E "^AUDIT (CLIP|CUT|OFF|FLAT)|SCRIPT ERROR" | grep -vE "\[(novn|notips|boost|clear:60|close|scale=[0-9.]+|gset:[^]]*)\]" | sort -u)
  local SOFT=$(echo "$LOG" | grep -E "^AUDIT (TRIM|OVER)" | sort -u | wc -l | tr -d ' ')
  local N=$(echo "$LOG" | grep -c "^SHOT")
  if [ -n "$BAD" ]; then echo "AUDIT $1: FAIL ($N steps)"; echo "$BAD"; FAIL=1; else echo "AUDIT $1: PASS ($N steps, $SOFT soft notes)"; fi
}
run "1280x720 default" "" ""
if [ "$1" != "quick" ]; then
  run "1280x720 narrow canvas (scale 1.23)" "" "scale=1.2308,"
  run "1560x720 phone, X-LARGE" "--resolution 1560x720" "scale=1.3,"
fi
[ $FAIL -eq 0 ] && echo "AUDIT: PASS" || { echo "AUDIT: FAIL"; exit 1; }
