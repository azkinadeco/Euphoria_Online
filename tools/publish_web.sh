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

# GitHub rejects files over 100 MB: split the .pck into parts and let index.html stream them back together.
PCK=web/Euphoria_v2.pck
SIZE=$(stat -f%z $PCK)
if [ $SIZE -gt 95000000 ]; then
  split -b 60m -a 1 $PCK web/Euphoria_v2.pck.part
  rm $PCK
  PARTS=$(cd web && ls Euphoria_v2.pck.part? | sed 's/.*/"&"/' | paste -sd, -)
  python3 - "$PARTS" <<'PY'
import sys
parts = sys.argv[1]
shim = """		<script>
		// Euphoria_v2.pck is split into parts (GitHub's 100 MB file limit): stream them back as one response.
		(function () {
			const PARTS = [%s];
			const nativeFetch = window.fetch.bind(window);
			window.fetch = function (input, init) {
				const url = typeof input === 'string' ? input : input.url;
				if (!/Euphoria_v2\\.pck(\\?|$)/.test(url)) {
					return nativeFetch(input, init);
				}
				let i = 0;
				let reader = null;
				const body = new ReadableStream({
					async pull(controller) {
						for (;;) {
							if (!reader) {
								if (i >= PARTS.length) { controller.close(); return; }
								const r = await nativeFetch(PARTS[i++], init);
								if (!r.ok) { throw new Error('Failed loading ' + PARTS[i - 1]); }
								reader = r.body.getReader();
							}
							const res = await reader.read();
							if (res.done) { reader = null; continue; }
							controller.enqueue(res.value);
							return;
						}
					},
				});
				return Promise.resolve(new Response(body, { status: 200, headers: { 'Content-Type': 'application/octet-stream' } }));
			};
		})();
		</script>
""" % parts
p = 'web/index.html'
s = open(p).read()
tag = '\t\t<script src="Euphoria_v2.js"></script>'
assert tag in s
s = s.replace(tag, shim + tag, 1)
open(p, 'w').write(s)
PY
  echo "split $PCK into: $PARTS"
fi
