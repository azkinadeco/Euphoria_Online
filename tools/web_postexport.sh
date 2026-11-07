#!/bin/zsh
# Run after exporting the Web build: puts the app icon at the default paths iOS/browsers look for.
cd "$(dirname "$0")/.."
cp art/brand/app_icon_180.png builds/apple-touch-icon.png
cp art/brand/app_icon_180.png builds/apple-touch-icon-precomposed.png
python3 -c "from PIL import Image; Image.open('art/brand/app_icon_256.png').convert('RGBA').save('builds/favicon.ico', sizes=[(16,16),(32,32),(48,48),(64,64)])"
echo "web icons copied"
# keep only the embedded (data URI) touch icon so iOS never needs a separate download
python3 - <<'PY'
p = 'builds/Euphoria_v2.html'
t = open(p, encoding='utf-8').read()
t = t.replace('<link rel="apple-touch-icon" href="Euphoria_v2.apple-touch-icon.png"/>', '')
open(p, 'w', encoding='utf-8').write(t)
PY
echo "html touch icon cleaned"
