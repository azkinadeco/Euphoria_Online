import http.server
import socketserver
import webbrowser
import os
import sys
import socket

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "builds", "web")

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Sambungkan ke dummy IP publik untuk mendapatkan IP lokal yang aktif di Wi-Fi
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

class GodotWebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Header esensial agar WebAssembly Godot berjalan tanpa hambatan di PC maupun HP
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    local_ip = get_local_ip()
    phone_url = f"http://{local_ip}:{PORT}"
    local_url = f"http://localhost:{PORT}"
    
    try:
        with socketserver.TCPServer(("0.0.0.0", PORT), GodotWebHandler) as httpd:
            print("==================================================================")
            print("🎮 EUPHORIA ONLINE — LOCAL WEB SERVER")
            print("==================================================================")
            print(f"💻 Browser Mac (PC)   : {local_url}")
            print(f"📱 Browser HP (Mobile): {phone_url}")
            print("------------------------------------------------------------------")
            print("💡 PANDUAN BUKA DI HP:")
            print(f"1. Pastikan HP & Mac terhubung ke WI-FI YANG SAMA.")
            print(f"2. Buka Chrome atau Safari di HP.")
            print(f"3. Ketik alamat ini di HP: {phone_url}")
            print("------------------------------------------------------------------")
            print("Tekan Ctrl + C di jendela Terminal ini untuk menghentikan server.")
            print("==================================================================")
            webbrowser.open(local_url)
            httpd.serve_forever()
    except Exception as e:
        print(f"\n❌ Gagal menjalankan server di port {PORT}: {e}")
        print("Jika port 8080 masih terpakai oleh proses sebelumnya, silakan tutup Terminal lama lalu coba lagi.")
