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
