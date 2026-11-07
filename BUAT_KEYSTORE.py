import os
import subprocess
import shutil

def main():
    print("==================================================")
    print("🔑 GENERATOR DEBUG KEYSTORE UNTUK GODOT ANDROID")
    print("==================================================")
    
    # 1. Cari binary keytool di Mac
    possible_keytools = [
        "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool",
        "/Applications/Android Studio.app/Contents/jre/Contents/Home/bin/keytool",
        "keytool"
    ]
    
    keytool_bin = None
    for k in possible_keytools:
        if os.path.exists(k) or k == "keytool":
            keytool_bin = k
            break
            
    if not keytool_bin:
        print("❌ Tidak dapat menemukan keytool. Pastikan Android Studio sudah terinstall di /Applications/Android Studio.app")
        return

    # 2. Lokasi output
    home_dir = os.path.expanduser("~")
    android_dir = os.path.join(home_dir, ".android")
    os.makedirs(android_dir, exist_ok=True)
    home_keystore = os.path.join(android_dir, "debug.keystore")
    
    project_dir = os.path.dirname(os.path.abspath(__file__))
    project_keystore = os.path.join(project_dir, "debug.keystore")

    # Jalankan pembuatan jika belum ada
    if not os.path.exists(home_keystore):
        print(f"Sedang membuat keystore baru...")
        cmd = [
            keytool_bin,
            "-keyalg", "RSA",
            "-genkeypair",
            "-alias", "androiddebugkey",
            "-keypass", "android",
            "-keystore", home_keystore,
            "-storepass", "android",
            "-dname", "CN=Android Debug,O=Android,C=US",
            "-validity", "9999",
            "-deststoretype", "pkcs12"
        ]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0 and not os.path.exists(home_keystore):
                print(f"❌ Error: {res.stderr}")
                return
        except Exception as e:
            print(f"❌ Exception: {e}")
            return

    # Salin juga ke folder project agar mudah dipilih di Godot tanpa buka hidden folder
    try:
        shutil.copyfile(home_keystore, project_keystore)
    except Exception:
        pass

    print("\n🎉 BERHASIL!")
    print(f"✅ debug.keystore siap di:")
    print(f"   1. Folder Project: {project_keystore}")
    print(f"   2. Folder Default: {home_keystore}")
    print("==================================================")

if __name__ == '__main__':
    main()
