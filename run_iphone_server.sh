#!/bin/zsh
# Fast Multi-Threaded HTTPS Server for Euphoria Online on iPhone Safari (with .pck/.wasm caching)

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/builds"

mkdir -p "$BUILD_DIR"

LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null)
if [ -z "$LOCAL_IP" ]; then
	LOCAL_IP=$(ipconfig getifaddr en1 2>/dev/null)
fi
if [ -z "$LOCAL_IP" ]; then
	LOCAL_IP="localhost"
fi

CERT_FILE="$BUILD_DIR/iphone_cert.pem"
KEY_FILE="$BUILD_DIR/iphone_key.pem"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
	echo "🔒 Membuat sertifikat HTTPS lokal untuk iPhone Safari..."
	openssl req -x509 -newkey rsa:2048 -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 -nodes \
		-subj "/CN=$LOCAL_IP" >/dev/null 2>&1
fi

echo "========================================================"
echo "⚡ EUPHORIA ONLINE — TURBO IPHONE HTTPS SERVER"
echo "========================================================"
echo "📦 Ukuran file di folder builds/:"
ls -lh "$BUILD_DIR" | grep -E '\.(pck|wasm|html|js)$' || echo "   (Belum ada file hasil export di builds/)"
echo "--------------------------------------------------------"
echo "👉 Buka di Safari iPhone: https://$LOCAL_IP:8443/Euphoria_v2.html"
echo "💡 Loading pertama mengunduh .wasm + .pck via Wi-Fi."
echo "   Loading ke-2 dst otomatis memakai Cache iPhone (2-3 detik)!"
echo "========================================================"

cd "$BUILD_DIR"

python3 - <<EOF
import http.server
import ssl

class FastGodotHandler(http.server.SimpleHTTPRequestHandler):
	protocol_version = "HTTP/1.1"

	def end_headers(self):
		self.send_header("Access-Control-Allow-Origin", "*")
		self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
		self.send_header("Access-Control-Allow-Headers", "*")
		# Cache file besar (.pck dan .wasm) di memori iPhone supaya tidak download ulang!
		if self.path.endswith(".pck") or self.path.endswith(".wasm") or self.path.endswith(".png"):
			self.send_header("Cache-Control", "public, max-age=86400")
		else:
			self.send_header("Cache-Control", "no-cache")
		super().end_headers()

server_address = ("0.0.0.0", 8443)
httpd = http.server.ThreadingHTTPServer(server_address, FastGodotHandler)

ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(certfile="$CERT_FILE", keyfile="$KEY_FILE")
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

print("🚀 Turbo Multi-Threaded HTTPS Server aktif di port 8443...")
httpd.serve_forever()
EOF
