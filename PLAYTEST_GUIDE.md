# Panduan Playtest Euphoria Online (14 hari)

Tujuan: tahu **apakah orang luar mau main lagi besok**, di mana mereka berhenti, dan apa yang bikin bingung, **sebelum** menambah fitur atau memasang backend. Selama playtest: **fitur dibekukan**. Yang boleh diubah hanya bug dan hal yang terbukti bikin orang berhenti.

---

## 1. Siapa yang dicari

- **20–50 orang** yang memang main gacha / RPG koleksi karakter (Brown Dust, Sakura-like, Nikke, Epic Seven, dst.). Bukan teman yang "main karena sungkan".
- Campur HP Android, iPhone, dan PC. Paling penting: **HP kelas menengah** (web build ±150 MB, harus dicek di HP nyata).
- Minimal **5 orang yang kamu tonton langsung** (video call share screen / duduk di sebelahnya). Jangan bantu, jangan jelaskan. Catat kapan mereka bingung, diam, atau bilang "terus ini ngapain?".

**Bias yang harus diwaspadai**
- Teman dan keluarga terlalu baik. Nilai dari mereka jangan dihitung sama dengan orang asing.
- Orang yang direkrut dari komunitas gacha cenderung lebih toleran grinding daripada pemain umum.
- 20 orang itu kecil: anggap angka sebagai **arah**, bukan kepastian statistik.

## 2. Tempat cari tester

- Discord/grup komunitas gacha Indonesia (izin admin dulu, baca aturan promosi).
- Reddit: subreddit gacha / indie game yang mengizinkan playtest post (cek aturan self-promo tiap subreddit).
- itch.io (upload sebagai "playtest build"), grup Facebook/Telegram game mobile.
- Jangan spam. Satu posting jujur > sepuluh posting generik.

## 3. Template pesan

**Bahasa Indonesia**
> Halo! Aku lagi bikin game gacha strategi "Euphoria Online" (indie, sendirian). Lagi cari 30 orang buat coba **versi tes** di browser HP/PC, gratis, tanpa top-up.
> Mainnya bebas, cukup **mainkan seperti biasa selama beberapa hari**. Kalau sempat, setelah 2–3 hari buka **Settings → PLAYTEST DATA → SEND LOG** lalu kirim filenya ke aku. Log itu anonim (tanpa nama, tanpa IP) dan cuma tersimpan di HP kamu sampai kamu kirim sendiri.
> Link: <LINK>
> Kritik pedas sangat diterima. Makasih!

**English**
> Hi! I'm a solo dev making "Euphoria Online", a strategy gacha RPG. Looking for ~30 players to try a **test build** in the browser (phone or PC), free, no real-money purchases.
> Just play normally for a few days. After 2–3 days, if you can, open **Settings → PLAYTEST DATA → SEND LOG** and send me the file. The log is anonymous (no name, no IP) and stays on your device until you send it.
> Link: <LINK>
> Honest/harsh feedback is very welcome. Thanks!

## 4. Jadwal

| Hari | Kerjaan |
|---|---|
| 1 | `zsh tools/publish_web.sh` (+ `zsh tools/web_postexport.sh`), push, cek link di HP sendiri. Judul game harus menampilkan **PLAYTEST BUILD &lt;versi&gt;**. |
| 1–3 | Rekrut + kirim link. Tonton 5 orang main langsung. |
| 3–10 | Game otomatis menanyakan rating setelah Chapter 1/3/6 dan mengingatkan kirim log mulai hari ke-2. Ingatkan manual sekali lewat chat. |
| 10–12 | Kumpulkan semua file log di satu folder, jalankan report. |
| 13–14 | Ambil keputusan (bagian 7). |

**Jangan** ganti build di tengah playtest kecuali ada bug yang bikin orang macet. Kalau terpaksa, report bisa dipisah per versi (`--build`).

## 5. Mengumpulkan & membaca log

```
mkdir -p playtest_logs        # taruh semua file euphoria_playtest_*.json / teks COPY di sini
python3 tools/playtest_report.py playtest_logs/
python3 tools/playtest_report.py playtest_logs/ --build 1a2b3c4      # hanya satu versi build
python3 tools/playtest_report.py playtest_logs/ --csv tester.csv    # tabel per tester (Excel/Sheets)
```

Kalau tester mengirim **COPY TEXT**, simpan teksnya sebagai file `.json` di folder yang sama. File dobel dari orang yang sama otomatis diambil yang paling lengkap.

> Folder `playtest_logs/` jangan di-commit ke git publik (itu data orang lain, walaupun anonim).

**Cara membaca bagian report**

| Bagian | Pertanyaan yang dijawab |
|---|---|
| RETENTION D1/D3/D7 | Apakah mereka balik? Ini angka paling penting. |
| FUNNEL (first session) | Di langkah mana sesi pertama putus (lobby → battle → menang → summon → upgrade → Chapter 1). |
| PLAY TIME UNTIL | Berapa menit main sampai momen penting. Kalau summon pertama > 10 menit, onboarding terlalu panjang. |
| LAST SCREEN BEFORE THEY STOPPED | Layar terakhir sebelum orang pergi = kandidat masalah. |
| SCREENS OPENED | Fitur yang hampir tidak pernah dibuka = beban maintenance, kandidat dipangkas. |
| PERFORMANCE | Lama boot dan FPS per layar di HP asli. Layar < 30 fps = prioritas perbaikan. |
| MOST LOST BATTLES / after a defeat | Tembok kesulitan, dan apakah orang memilih RETRY, UPGRADE atau pergi. |
| BATTLES LEFT HALF-WAY | Battle yang ditinggal = membosankan atau terlalu lama. |
| ECONOMY WALLS | Energy/gold/gem habis di mana. Ini tanda grinding. |
| STORY / TUTORIAL TEXT | Persentase VN yang di-skip. Kalau > 60% di-skip, teks terlalu panjang atau kurang menarik. |
| QUICK RATINGS + tag | Rasa umum dan keluhan yang paling sering dipilih. |
| WRITTEN FEEDBACK | Kutipan langsung. Cari pola, bukan satu komentar paling keras. |

## 6. Pertanyaan wawancara (5 orang yang ditonton)

1. "Kalau game ini hilang besok, kamu kecewa nggak? Kenapa?"
2. "Bagian mana yang paling bikin kamu mau lanjut? Bagian mana yang bikin pengin tutup?"
3. "Ceritakan dengan kata-katamu sendiri, game ini tentang apa dan tujuanmu apa."
4. "Kamu biasanya main gacha apa? Apa yang bikin kamu bertahan di sana?"
5. "Kalau game ini ada di Play Store, kamu akan download? Ajak teman?"

Jangan tanya "bagus nggak?". Jawabannya hampir selalu "bagus" dan tidak berguna.

## 7. Keputusan setelah 14 hari

**Ambang usulan, bukan benchmark industri.** Sesuaikan setelah melihat data pertama.

| Hasil | Arti | Langkah |
|---|---|---|
| D1 ≥ 40% **dan** ≥ 3 orang tanya sendiri "kapan rilis / ada banner apa" | Core loop menarik | Lanjut: pilih target rilis (web/itch, Steam, atau mobile), lalu baru pikirkan backend. |
| D1 20–40% | Ada sesuatu, tapi bocor | Perbaiki 3 titik drop-off teratas dari report, ulangi playtest 7 hari dengan orang baru. |
| D1 < 20% atau median sesi pertama < 10 menit | Masalah di 30 menit pertama | **Jangan tambah konten.** Rombak onboarding / battle pertama / kejelasan tujuan. |
| Hampir semua layar "fitur sampingan" < 20% dibuka | Fitur terlalu banyak | Sembunyikan / pangkas, fokus ke 3–4 loop utama. |
| FPS < 30 di banyak HP atau boot > 60 detik | Masalah teknis menghalangi | Prioritas ukuran download & performa sebelum hal lain. |

## 8. Privasi (yang dijanjikan ke tester)

- Isi log: id acak, platform kasar (mis. `web_android`), ukuran layar, waktu, layar yang dibuka, hasil battle, summon, level, FPS, rating, dan teks feedback yang mereka tulis sendiri.
- **Tidak** ada nama pemain, isi save, IP, atau data kontak. Tidak ada yang dikirim otomatis.
- Tester bisa mematikan rekaman dan menghapus log di Settings → PLAYTEST DATA.
- Simpan log hanya untuk analisis game ini; hapus setelah keputusan diambil.
