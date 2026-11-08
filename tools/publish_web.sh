#!/bin/zsh
# Export the web build into web/ (served by Vercel, see vercel.json).
# Run from the project root:  zsh tools/publish_web.sh   then commit + push web/.
set -e
setopt NULL_GLOB
GODOT=${GODOT:-/Users/apple/Downloads/Godot.app/Contents/MacOS/Godot}
$GODOT --headless --path . --export-release "Web" builds/Euphoria_v2.html
mkdir -p web
rm -f web/Euphoria_v2.*
cp builds/Euphoria_v2.* web/
cp web/Euphoria_v2.html web/index.html
for f in favicon.ico apple-touch-icon.png apple-touch-icon-precomposed.png; do
  [ -f builds/$f ] && cp builds/$f web/
done
touch web/.gdignore
ls -la web | awk '{print $5, $9}'

# GitHub rejects files over 100 MB: split the .pck into parts. tools/web_loader.js streams them back
# together and resumes any download that a mobile browser cut off (tab in the background).
PCK=web/Euphoria_v2.pck
SIZE=$(stat -f%z $PCK)
PARTS='"Euphoria_v2.pck"'
if [ $SIZE -gt 95000000 ]; then
  split -b 60m -a 1 $PCK web/Euphoria_v2.pck.part
  rm $PCK
  PARTS=$(cd web && ls Euphoria_v2.pck.part? | sed 's/.*/"&"/' | paste -sd, -)
  echo "split $PCK into: $PARTS"
fi
python3 - "[$PARTS]" <<'PY'
import sys
js = open('tools/web_loader.js').read().replace('__PARTS__', sys.argv[1])
for p in ('web/index.html', 'web/Euphoria_v2.html'):
    s = open(p).read()
    tag = '\t\t<script src="Euphoria_v2.js"></script>'
    assert tag in s
    s = s.replace(tag, '\t\t<script>\n' + js + '\t\t</script>\n' + tag, 1)
    open(p, 'w').write(s)
PY
echo "web loader injected"
