# Euphoria Online v2 — Analisa & Rebuild

## 1. Analisa versi lama (Foundation 61–111)

| Masalah | Detail |
|---|---|
| Kode menumpuk | ±25.000 baris. `scripts/foundation21_24.gd` (6.161 baris), `ui/production_visual_shell.gd` (4.475), `ui/production_auxiliary_shell.gd` (4.020). Puluhan "manager" dibuat tapi hampir tidak dipakai. |
| Data palsu / hardcode | Bag, Arena, Dungeon, Shop, Story menampilkan angka statis ("Chapter 12", "Power 2,487,312", "Abyss Core x99"), bukan state pemain sebenarnya. |
| Angka tidak konsisten | Header menampilkan Gold 5.202.620, panel di bawahnya 1.284.500 pada layar yang sama. |
| Hero placeholder | Lilith, Lora, Kael, Seraphine, Morrigan dll. tidak punya artwork asli → tampil sebagai chibi gambar-prosedural, sementara 17 hero asli di folder `Karakter Euphoria Online` hanya sebagian dipakai. |
| Layout rusak | Konten terpotong di bawah navigasi, header dobel, teks bertumpuk, overlay transisi menutupi layar (Tavern/World tampil gelap). |
| Battle | Bukan mekanik Brown Dust: tombol Attack/Skill manual, damage acak, formasi tidak mempengaruhi hasil. |

## 2. Perbandingan dengan Sakura Oath & Brown Dust 1

| Fitur | Brown Dust 1 / Sakura Oath | Versi lama | **v2 (sekarang)** |
|---|---|---|---|
| Grid 3x3 per sisi, kolom depan/tengah/belakang | ✔ | tampilan saja | ✔ dipakai di battle |
| Urutan aksi = urutan deploy (bergantian Ally#1→Enemy#1…) | ✔ | ✘ | ✔ |
| Skill dengan pola area (single, pierce, baris, kolom, silang, 2x2, X, semua) | ✔ | ✘ | ✔ + diagram jangkauan |
| Lihat formasi musuh sebelum battle + preview area skill | ✔ | ✘ | ✔ (highlight target real-time) |
| Auto-battle, speed x1/x2/x3, skip | ✔ | sebagian | ✔ |
| Elemen (Fire>Wind>Earth>Water>Fire, Light⇄Dark) | ✔ | teks saja | ✔ (+30% / −15%) |
| Status: stun/freeze, burn/poison, shield, drain, buff ATK, DEF down, execute | ✔ | ✘ | ✔ |
| 3 bintang (menang, tanpa korban, ≤3 ronde), sweep | ✔ | statis | ✔ |
| Gacha banner rate-up, pity, x10 jaminan SR, duplikat → shard | ✔ | sebagian | ✔ + animasi gerbang, flip kartu, splash SSR |
| Level, Star Up (naik level cap), evolusi sprite | ✔ | sebagian | ✔ (sprite evo di 5★) |
| Outfit/skin dibuka bertahap (Sakura Oath) | ✔ | ✘ | ✔ semua artwork hero bisa dibuka (★, Bond 4/7/10, Oath) |
| Affection/Bond, hadiah, Oath Ring | ✔ | statis | ✔ (+2%/level, Oath +10%) |
| Lobby partner interaktif (tap → voice line, hati) | ✔ | sebagian | ✔ + pilih hero lobby |
| Story chapter + dialog cutscene | ✔ | statis | ✔ 6 chapter × 6 stage, dialog intro & boss |
| AFK / idle reward | ✔ | statis | ✔ real-time, cap 12 jam |
| Energy regen | ✔ | ✘ | ✔ 1/3 menit |
| Daily mission & achievement, Mail, Shop harian | ✔ | statis | ✔ fungsional |
| Arena PvP async | ✔ | statis | ✔ lawan AI, RP, tiket harian, Arena Shop |
| Tower | ✔ | statis | ✔ lantai tak terbatas, guardian tiap 5 lantai |
| Save otomatis | ✔ | sebagian | ✔ JSON di `user://euphoria_v2_save.json` |

## 2b. Update batch 2

| Fitur | Isi |
|---|---|
| Equipment | Weapon / Armor / Accessory, rarity R/SR/SSR, enhance +10, auto-equip, salvage. Drop dari story (boss pasti), tower, Gear Chest (Shop/Guild/Event/Login). Tab GEAR di Hero & Bag. |
| Login 7 hari | Kalender hadiah, muncul otomatis di lobby tiap hari. |
| Event "Moonlit Festival" | 5 stage event (Lv.4–46), Moon Token, Exchange (shard Lumeira, tiket, Oath Ring, gear), periode 14 hari dengan timer. |
| Guild | Gabung/buat guild, check-in & donasi harian, level guild = buff +1% ATK/HP per level, Raid Boss bersama (3x/hari, HP berkurang juga oleh anggota lain), ranking anggota, Guild Shop. |

## 2c. Update batch 3

- Layout Event & Guild dirapikan; semua layar dicek di rasio iPhone (1560×720).
- Ukuran UI otomatis lebih besar di layar sentuh (Settings → UI Size: Auto/Normal/Large/X-Large); lobby & formasi menyesuaikan tinggi layar.
- Build web 162 MB → 34 MB (tekstur karakter dikompres WebP + batas resolusi saat import; file asli tidak diubah).
- Friend/Support: kirim hati (Friend Point), pinjam 1 hero teman di Story/Event/Tower (sekali per teman per hari), Friend Shop.
- Artwork Scylla dibersihkan dari latar kotak-kotak (checkerboard) yang ikut tercetak; file lama di-backup.

## 2d. Update batch 4

- Logo resmi: ikon aplikasi/desktop/web/iOS (`art/brand/app_icon.png`), boot splash & loading web (emblem), Title Screen baru (emblem + hero acak, TAP TO START), logo teks di Settings.
- Battle VFX: lingkaran sihir sesuai elemen, tebasan + percikan saat kena, proyektil, cut-in nama skill untuk boss & skill area.
- Panduan "NEXT ▶" di lobby: menunjukkan langkah berikutnya (mail → summon → story → misi → level up/gear → guild).
- Cerita penutup setiap chapter + hadiah Chapter Clear (300 Gems, 3 Tiket, Gear Chest).

## 2e. Update batch 5

- Daily Dungeon: Golden Vault (Gold), Crystal Sanctum (Hero EXP + potion), Armory Ruins (gear + Gear Chest). 5 level, 3 percobaan/hari per dungeon, gagal = percobaan dikembalikan, Sweep untuk level yang sudah clear. Misi harian baru "Clear a Daily Dungeon".
- Memories (Bond Story): 3 episode per hero (Bond 3/6/10) dengan dialog dan hadiah baca pertama; badge di menu Heroes.
- Badge baru di lobby: Dungeon (sisa percobaan), Guild (belum check-in), Heroes (memory baru).

## 2f. Update batch 6 — Battle FX & Sound

- 19 SFX battle + BGM battle & boss (dibuat prosedural oleh `tools/gen_battle_audio.py`, folder `audio/battle/`). Suara per elemen (fire, ice, water, wind, thunder, earth, light, dark), slash, hit, crit, cast, heal, buff/debuff, dash, death, gong ronde. BGM berganti otomatis (crossfade) saat masuk/keluar battle.
- `game/ui/skill_fx.gd`: efek skill vektor per elemen (api, es, air, angin, petir, batu, pilar cahaya, vortex gelap) + per pola area (beam baris, pilar kolom, gelombang semua, ledakan area), aura caster, heal, efek kematian.
- Animasi: hero melee (Warrior/Assassin/Knight/Paladin/Tank) berlari ke target lalu menebas; caster naik + bersinar lalu merapal. Cut-in wajah untuk boss/skill area. Layar bergetar lebih kuat saat critical.
- Statistik battle (damage, heal, damage diterima per hero).
- Skill Level 1–5 (+12% kekuatan skill per level) dengan Skill Book (Crystal Sanctum, Arena Shop, Gold Shop, Season Pass).
- Season Pass 30 level (28 hari), jalur Free + Premium (980 Gems); Pass EXP dari stage, dungeon, arena, guild, AFK, summon, misi.

## 2g. Update batch 7 — Voice & Memories

- Voice line Jepang untuk 17 hero × 6 kategori (greet, tap, bond, skill, win, summon) = 102 file di `audio/voice/`.
  Dibuat dengan TTS macOS (suara "Kyoko") + pitch/tempo berbeda per hero (`tools/gen_voices.py`). Subtitle bahasa Inggris tampil di game.
  Dipakai di: sapaan & sentuhan lobby, teriakan skill di battle, quote MVP saat menang, splash SSR gacha, panel ♪ VOICE di halaman hero (Affection terbuka di Bond 5), hadiah bond.
- Memories: 3 episode cerita khusus per hero (51 episode) sesuai kepribadian masing-masing.
- Dialog tengah chapter (stage ke-3) di setiap chapter. Slider volume Voice di Settings.

### Cara mengedit naskah
- Voice: edit `data/voice_lines.json` (`jp` = yang diucapkan, `en` = subtitle, `pitch`/`rate` per hero), lalu jalankan `python3 tools/gen_voices.py` (atau `python3 tools/gen_voices.py shina` untuk satu hero).
- Memories: edit `data/memories.json` langsung (judul + baris `[speaker, teks]`, speaker `commander` = pemain). Tidak perlu generate ulang.
- Catatan lisensi: suara TTS macOS cocok untuk prototipe/testing. Untuk rilis komersial gunakan voice actor atau TTS berlisensi komersial (mis. VOICEVOX dengan karakter yang mengizinkan penggunaan komersial).

## 2h. Update batch 8 — Animasi UI & fitur Sakura Oath/Brown Dust

- Animasi UI: transisi layar slide+fade (arah mundur saat Back), kartu/daftar muncul berurutan di semua menu, tombol membesar saat hover & memantul saat ditekan, badge berdenyut, angka mata uang naik bertahap, popup hadiah dengan ikon muncul satu per satu + cahaya berputar, node story muncul pop-in, partikel cahaya melayang (lobby, title, gacha, hero, story, garden, gallery, expedition), artwork hero slide saat ganti.
- Garden (asrama): sampai 6 hero chibi berjalan bebas; sentuh = lompat + hati + voice + Bond EXP (5x/hari per hero) + kadang hadiah. Tombol RESIDENTS untuk memilih penghuni.
- Gallery/Album CG: 75 artwork, layar penuh dengan zoom (scroll/pinch/tombol/klik ganda) & geser, tombol jadikan lobby.
- Expedition: 5 misi berwaktu (1–8 jam), pilih hero (min level), timer live, klaim / selesaikan instan dengan Gems, +10 Bond EXP per hero.
- Formation Preset: TEAM 1/2/3.
- Collection Bonus: +0,5% HP/ATK/DEF per hero yang dimiliki.

## 2i. Update batch 9 — Sistem & animasi battle

- Passive per role: Iron Guard (Tank/Paladin/Knight −15% damage), Battle Rage (Warrior +8% ATK/ronde, max +40%), Precision (Assassin +20% crit, crit x1.9), Arcane Pierce (Mage/Warlock abaikan 25% DEF), Hunter's Eye (Ranger +20% ke non-front), Grace (Healer/Buffer heal 6% di akhir ronde).
- Synergy elemen tim: 2/3/4/5 hero elemen sama → +5/10/15/20% ATK & HP (berlaku juga untuk musuh).
- Field effect per chapter (mis. Forest Breeze: WIND +15% ATK) — tampil di Story & awal battle.
- Boss ENRAGE di bawah 50% HP (+30% ATK) dengan animasi khusus.
- Animasi battle: ikon status (Burn/Stun/Shield/ATK▲/DEF▼) di bawah HP bar, jejak HP putih, panah giliran, "SHIELD BREAK", camera punch saat crit/cut-in, efek passive, banner synergy/field di awal, tombol PAUSE (resume/skip), perayaan kemenangan (lompat + confetti).
- Settings: opsi lewati cut-in. 5 achievement baru (Tower 25, 150 summon, skill Lv.5, 10 Memories, Pass Lv.30).

## 2j. Update batch 10 — Interaksi karakter, Rune, Kostum, Mini-game, Arena Season

- Lobby: zona sentuh (kepala = elus + hati + voice affection, badan = malu/goyang + rona, kaki = kaget melompat + "!"), aksi idle acak (lompat, goyang, aura), parallax hero/latar mengikuti kursor, tombol OUTFIT untuk ganti kostum cepat.
- Rune (Brown Dust): 4 jenis (Fury ATK, Vitality HP, Guard DEF, Precision CRIT), Tier 1–5, 3 slot per hero (tab GEAR), AUTO, fusi 3→1 di Bag (tab RUNES) dengan efek. Sumber: Arena (30%), Tower guardian, Daily Dungeon, Rune Pouch/Grand Rune Chest di Shop. CRIT rune masuk ke perhitungan battle.
- Kostum: outfit terkunci bisa dibuka langsung dengan Gems (tab OUTFITS).
- Mini-game Heart Catch (dari Garden): 30 detik, hati pink/emas/bom, combo, hadiah Bond EXP + Gold (3x/hari).
- Arena Season mingguan: leaderboard 30 pemain, hadiah per tier di akhir season (LEGEND sampai BRONZE), RP soft reset.

## 2k. Update batch 11 — Awakening, Black Market, 10 hero baru, penjaga toko

- Confetti kemenangan dihapus; interaksi Garden = lompat + sprite sedikit membesar.
- Awakening A1–A5 (setelah 6★): +6% HP/ATK/DEF per level, A3 = skill +1 level, A5 = aura emas di battle. Label A# di kartu & battle.
- Black Market (tab di Shop): 6 tawaran acak harian dengan diskon (shard hero, rune T3, gear SSR, Oath Ring, dll.), refresh 3x/hari (50 Gems).
- Sentuh artwork di halaman hero: reaksi kepala/badan/kaki + voice.
- 10 hero baru (NEW HERO NOVEMBER 2026): Abadonia, Atalanta, Kali, Zennyo Ryuo (SSR); Aqua, Rubby, Schylua, Vexira (SR); Siv, Sven (R). Latar putih dihapus otomatis (`tools/import_new_heroes.py`), stat & skill sesuai tema, 6 voice + 3 Memories per hero (`tools/hero_content_nov2026.py`), 2 banner rate-up baru, mail hadiah 10 tiket + 1500 Gems.
- Penjaga toko "Lulu" di sisi kiri Shop (siang) dan Black Market (Night Shift): sapaan, voice, reaksi sentuh, ucapan terima kasih/kurang uang saat membeli.

## 2l. Update batch 12 — Presentasi & kenyamanan bermain

- Dialog cerita gaya visual novel (`game/ui/vn_dialogue.gd`): latar sesuai chapter, 2 karakter kiri/kanan (yang bicara terang + sedikit membesar, yang lain redup), papan nama berwarna tema hero, efek mengetik, tombol AUTO / LOG (riwayat percakapan) / SKIP.
- Tutorial pointer: panah + cincin berdenyut di tombol yang disarankan panduan NEXT (pemain di bawah Lv.8).
- Auto-Repeat x3/x5/x10 untuk Story, Event, Dungeon yang sudah pernah menang; berhenti otomatis saat kalah/energi habis, ringkasan hadiah.
- Carousel banner di lobby: banner rate-up, event, Season Pass, Black Market — berganti tiap 5 detik, bisa digeser manual.
- Riwayat summon (100 terakhir) dan filter elemen di daftar Heroes.

## 2m. Update batch 13 — Hasil audit (F1, F2, F10) + polish animasi

- F1 Lobby: menu kiri 4 tombol (Mail, Missions, Login, Event), navigasi bawah 5 tombol (Heroes, Formation, Story, Summon, MENU). Fitur lain di grid MENU dengan level buka: Garden/Gallery Lv.2, Dungeon/Pass Lv.3, Friends/Event Lv.4, Arena Lv.5, Tower/Expedition Lv.6, Guild Lv.7. Notifikasi "NEW FEATURE UNLOCKED", badge MENU = jumlah fitur yang punya sesuatu untuk diklaim. Player EXP per stage dinaikkan agar pembukaan fitur seiring story.
- F2 Ekonomi: summon hari pertama turun dari ~62 ke ~17. Sisanya dipindah ke Login 7 hari (total 21 tiket + 900 Gems) dan bonus tiket di stage ke-3 tiap chapter. 10x summon pertama dijamin SSR.
- F10: kode legacy (~25 ribu baris), dokumen FOUNDATION*, zip 89 MB, dan aset lama dipindah ke `../_ARSIP_LEGACY_2026-11-03/` (tidak dihapus).
- Animasi & efek: pilar cahaya warna rarity sebelum kartu gacha dibuka + sinar berputar & kilau untuk SR/SSR; efek upgrade di halaman hero (Level/Skill/Star/Awaken/Outfit) dengan ledakan elemen, gelombang, teks besar, lompatan; hati beterbangan saat memberi hadiah; titik cahaya mengalir di jalur story yang sudah clear; hero jatuh ke petak formasi dengan efek pendaratan; emote acak (♪ ♥ … zZ ! ?) di Garden; riak cahaya di titik sentuh lobby; sprite tertekan saat terkena serangan di battle.

## 2n. Update batch 14 — Backup save, aksesibilitas, tutorial, Hard Mode

- F3 Backup: Settings → BACKUP CODE (salin kode teks, gzip+base64) dan RESTORE FROM CODE. Kode lama/rusak ditolak.
- F7: opsi "Reduce effects" (tanpa kilat layar, getaran, camera punch di battle & gacha). F6: ukuran teks minimum 12 px.
- Tutorial pertama kali (sekali per save) lewat dialog VN di Formation, Summon, Hero, Story, Dungeon, Arena, Garden, Expedition, Guild.
- Story HARD Mode: 36 stage tambahan (musuh +14 level, 3★/4★, unit ekstra, energi +4). Terbuka per chapter setelah boss Normal dikalahkan. Drop shard hero dijamin (R/SR di stage biasa, SSR di boss), Gems first clear, Sweep & Auto-Repeat.

## 2o. Update batch 15 — Pendekatan karakter & efek

- Memories dengan pilihan jawaban: 3 opsi per episode; hero bereaksi dengan voice line-nya, Bond +40 (sesuai kepribadian) / +20 / +10. Kepribadian: Tank/Paladin/Knight/Healer/Buffer suka kebaikan & perlindungan, Warrior/Assassin/Ranger suka latihan, Mage/Warlock suka ditanya soal kekuatannya (`DB.liking`).
- Daily Talk (3x/hari): tombol TALK ♥ di lobby & tab BOND, topik acak dengan pilihan jawaban.
- Hadiah favorit per hero (x2 Bond), 2 hadiah baru: Sweet Cake (Gold) & Moonlight Perfume (Gems).
- Perayaan Bond Level Up layar penuh (hati, artwork, voice, daftar yang terbuka: Memory baru, voice Affection, outfit, Oath).
- Hero lobby kadang bicara sendiri saat Bond ≥3.
- Efek: ikon hadiah terbang ke header saat klaim; hero & musuh masuk ke arena dengan animasi di awal battle.

## 2p. Update batch 16 — Tampilan & konten jangka panjang

- Lobby: pencahayaan mengikuti jam (pagi keemasan, siang, sore jingga, malam biru + bintang), berkas cahaya bergoyang, ring progres misi harian "TODAY" (tap = Missions).
- Semua layar: pita header gradasi + garis emas, ikon berdenyut per layar, vignette di latar.
- Story Arc 2 (Chapter 7–10, 24 stage + Hard): "The Second Eclipse" — Kali, Abadonia, Zennyo, dan Vexira ter-corrupt jadi boss, lengkap dengan intro/mid/boss/outro dan field effect baru. Musuh Arc 2 berbintang 3–5 (konten endgame).
- Weekly Missions (reset tiap minggu): stage, summon, dungeon, arena, interaksi hero, 25 misi harian — hadiah besar termasuk Royal Gear Chest.
- Hero Codex (Heroes → CODEX): hadiah sekali per hero untuk Recruited, 5★, Bond 10, Awakening A5 (27 hero × 4 milestone).
- Achievement baru: tamat Arc 2, 30 stage Hard.

## 2q. Update batch 17 — Kedalaman battle + sisa audit

- Status baru: TAUNT (Fidelia, Lucidria, Abadonia — serangan single-target ditarik ke tank), SILENCE (Hyeonxa, Vexira — skill jadi serangan lemah), HEAL ▼ (Schylua, Eropatra — heal diblokir), REVIVE (Aqua, sekali per battle, 30% HP), CLEANSE (Furu, Aqua). Ikon status, animasi revive (pilar cahaya), teks "HEAL BLOCKED"/"CLEANSE".
- N1: label [AI] untuk lawan Arena, leaderboard, teman, dan anggota guild.
- N2: dialog sebelum battle pertama dipangkas (intro 2 baris, tutorial Story dihapus, tutorial Formation 2 baris, popup Login tidak muncul di sesi pertama).
- N3: tutorial mode ringkas (potret kecil, layar tetap terlihat, header tidak tertutup) + kolom depan grid di-highlight.
- N6: build web 59 → 52 MB (sprite 512 px, artwork 1200 px).

## 2r. Update batch 18 — Pengganti sementara untuk artist & aktor

Semua bisa diganti aset asli tanpa mengubah kode:

| Pengganti | Cara mengganti nanti |
|---|---|
| Shader pseudo-Live2D (`game/ui/live_art.gdshader`): napas, rambut/kain bergoyang, kepala mengangguk, rim light — di lobby, hero, title, dialog | Ganti TextureRect art dengan node Live2D/Spine |
| BGM prosedural `audio/bgm_lobby.wav`, `bgm_story.wav`, `bgm_gacha.wav` (`tools/gen_music.py`), berganti per layar | Timpa file dengan nama sama |
| Voice reaksi battle `*_hurt.wav`, `*_ko.wav` untuk 27 hero | Timpa file di `audio/voice/` atau edit `data/voice_lines.json` lalu `python3 tools/gen_voices.py` |
| Mode CG: Memory episode 3 & Oath tampil layar penuh dengan Ken Burns | Taruh `art/cg/<hero>_3.png` / `<hero>_oath.png` |
| Musuh Elite/Corrupted (`game/ui/corrupt.gdshader`) di Arc 2 & Hard | Tambah art musuh baru di database |
| Pembersih latar putih terkurung (`tools/clean_white_holes.py`, otomatis di import) | Ganti dengan PNG transparan dari artist |

## 2s. Update batch 19 — Sambutan, profil, ulang tahun, scene, bonus outfit

- Welcome Back: setelah pergi ≥1 jam, hero lobby menyambut dengan ringkasan (lama pergi, AFK, energi, expedition selesai, misi siap) + tombol CLAIM AFK.
- Profil hero (`data/profiles.json`, bisa diedit): ulang tahun, tinggi, suka, tidak suka, hobi, CV. Tampil di tab INFO.
- Ulang tahun hero: di hari ulang tahunnya, hero menyapa lewat dialog (mode CG, file `art/cg/<hero>_bday.png` opsional) dan memberi hadiah sekali per tahun (+120 Bond, Celestial Gem, Gems).
- Lobby SCENE: 10 latar lobby, terbuka per 6 stage story yang diselesaikan.
- Bonus outfit: outfit yang dipakai memberi +2% ATK & HP per tingkat (maks +10%).

## 2t. Update batch 20 — World Boss mingguan

- Menu → World Boss (terbuka di Player Lv.5). 5 bos bergilir tiap minggu (Astral Nine-Tail, Crypt Behemoth, Gelatinous Overlord, Corrupted Forest Queen, Eye of the Primordial), tampil dengan shader Corrupted.
- Kelemahan otomatis dari tabel elemen: hero elemen yang mengalahkan bos mendapat +30% ATK (field modifier).
- 3 serangan per hari, HP bos tak terbatas; damage dijumlah sepanjang minggu. Hadiah per serangan (gold + EXP potion) dan 7 tahap hadiah damage (30k → 5 juta: gems, tiket, chest, Celestial Gem).
- Peringkat mingguan [AI] (15 peserta, damage AI dikalibrasi dari Team Power pemain: ±3× Team Power per serangan). Hadiah peringkat minggu lalu diberikan saat membuka layar World Boss.
- Badge menu saat serangan hari ini belum dipakai atau ada hadiah siap.

## 2u. Update batch 21 — Story Arc 3 "The Hour of Dawn"

- 4 chapter baru (11–14, total 84 stage): Frozen Tomorrow, Burning Tomorrow, The Last Bastion, The Hour of Dawn.
- Plot: jam katedral berhenti; Eclipse ternyata dikirim dari masa depan di mana Commander gugur. Mora masa depan memutar jam pasir berkali-kali. Bos tiap chapter adalah Mirror Hero dari masa depan itu (Valeria, Eropatra, Fidelia, Mora) — tampil dengan shader Corrupted & label MIRROR. Penutup Arc 3 + teaser kelanjutan.
- Pembicara baru di VN: `mirror:<hero>` (nama "Mirror …", art corrupted) dan `nar` (narasi tanpa nama). Kartu judul ARC 2 & ARC 3.
- Adegan baru `mid2` (sebelum stage bos) di Arc 3; 4 pilihan dialog Commander yang memberi Bond (Valeria, Mora ×2, Fidelia).
- STORY ARCHIVE: tonton ulang adegan yang sudah dilihat per chapter (pilihan tidak memberi Bond lagi saat replay).
- Tab chapter dikelompokkan per Arc (ARC 1/2/3) supaya muat di layar.
- Balance: level musuh Arc 3 Lv.84–105 (kurva lebih landai), maks 1 Ygg-Naar per stage, pengali HP bos per chapter (`boss_hp`). Win-rate bos Arc 3 dengan tim Lv.70 + bonus endgame ±20–50% (`tools/balance_test.gd`).
- Achievement baru: Chapter 12 dan Clear Arc 3.

## 2v. Update batch 22 — Perbaikan warna art + Festival Musiman

- FIX: art karakter lebih gelap sejak batch 18. Penyebab: di Godot 4 `COLOR` di fragment shader sudah berisi tekstur, lalu shader mengalikan tekstur lagi (warna dikuadratkan). `live_art.gdshader` & `corrupt.gdshader` kini memakai warna vertex (modulate) asli — kecerahan terukur sama persis dengan file asli (0,559 vs 0,559).
- Festival Musiman otomatis mengikuti bulan kalender (12 bulan; `DB.FESTIVALS`): New Dawn, Sweetheart, Sakura Bloom, Rainbell, Summer Splash/Fireworks, Tsukimi, Moonlit Masquerade, Harvest Lantern (November), Starfall Winter.
- Partikel musiman (`game/ui/festival_fx.gd`): lampion, salju, kelopak, hati, daun, hujan, kunang-kunang — di lobby & layar Festival.
- Lantern Charm (`season_token`) dari kemenangan Story/Hard/Event/Dungeon/Tower (10 + 5 per hero unggulan di tim, maks 400/hari, juga dari Auto-Repeat).
- Layar Festival (tombol kiri lobby): 2 hero unggulan, adegan festival (+60 Bond sekali), Daily Wish gratis, Festival Exchange (tiket, gems, shard hero unggulan, Celestial Gem, hadiah, chest, energi), stok reset tiap festival.

## 2w. Update batch 23 — Commander Tactics

- 5 Tactic Commander (`DB.TACTICS`), satu dipasang di Battle Prep, aktif otomatis sekali per battle:
  Rally Cry (awal ronde 2, ATK tim +), Field Medic (awal ronde 3, heal + cleanse), Opening Barrage (awal ronde 1, damage ke semua musuh), Aegis Protocol (ally < 40% HP, shield tim), Second Wind (ally pertama gugur, revive).
- Terbuka di Player Lv.3/6/10/14/20; upgrade Lv.1–5 dengan Gold (batas level = 1 + Player Lv/8).
- Battle: banner pembuka "TACTIC: …", cut-in emas saat aktif, efek per unit. Damage Barrage ikut dihitung di World Boss & Guild Raid. Berlaku juga untuk Auto-Repeat.
- Dampak terukur (tactic Lv.3, bos 10-6 Lv.65): win-rate 10% → 12–47% tergantung tactic.
- Battle Prep: tombol Support & Tactic digabung satu baris supaya START BATTLE tidak terpotong.

## 2x. Update batch 24 — Spark & Profil Commander

- Spark: setiap pull di banner rate-up memberi 1 Summon Point untuk banner itu; 150 poin ditukar langsung dengan hero unggulan (animasi reveal SSR; bila sudah punya → shard duplikat). Banner Standard tidak memberi poin.
- Profil Commander (ketuk avatar di lobby): ganti nama (2–14 karakter), pilih avatar dari hero yang dimiliki, pilih gelar, statistik (hero, power, story, tower, arena, summon, oath, gelar).
- 12 gelar (`DB.TITLES`): Rookie Commander, Star Summoner, Hero Collector, Beloved Commander, Oathbound, Eclipse Breaker, Dawn of the Second Sun, Keeper of the Hour, Tower Conqueror, Arena Champion, Colossus Slayer, Grand Tactician. Gelar tampil di bawah nama di lobby.

## 2y. Update batch 25 — Story Arc 4 "The Last Light" + Interludes

- Arc 4 (Chapter 15–18, total 108 stage): Hollow Tide, Hollow Garden, Architect of Ruin, The Last Light. Eclipse ketiga = Noctis, the Hollow Star (bintang mati yang kesepian, memakan ikatan). Bos "Hollow" (Cthollia, Eurnipha, Xylia, Shina) — varian shader teal + label HOLLOW. Mirror Mora kembali lewat retakan jam pasir. Ending: Noctis dihangatkan (bukan dihancurkan), Commander selamat → masa depan Mora terhapus.
- 4 pilihan dialog baru (Mora, Eurnipha, Fidelia ×2 di Arc 4).
- Interludes (`DB.INTERLUDES`): 4 episode tanpa battle setelah tiap Arc — Tea at the Cathedral, The Freed Ones, Letters from Tomorrow, Starlight Afterparty. Baca pertama: 200 Gems + 1 Summon Ticket + 40 Bond untuk pemerannya. Tombol "✦ INTERLUDES (n NEW)" di peta story.
- Varian bos digeneralisasi (`variant`: mirror/hollow), `boss_hp` & `boss_atk` per chapter.
- Balance: kurva level Arc 3–4 Lv.84–117 (+4/chapter). Win-rate bos dengan tim endgame: Lv.70 → 10–60%, Lv.80 → 60–100%; bos final paling sulit.
- Achievement: Chapter 16, Clear Arc 4. Gelar baru: "The Last Light".

## 2z. Update batch 26 — Logo aplikasi baru + Story Links

- Logo baru (`Logo Euphoria Online Dekstop.png`) dipakai untuk favicon, ikon "Add to Home Screen" iPhone (apple-touch-icon 180), dan ikon PWA (144/180/512) saat "Install app" di desktop. Ikon lama disimpan sebagai `art/brand/app_icon_old_backup.png`.
- PWA diaktifkan (manifest + service worker, orientasi landscape, nama "Euphoria Online", meta apple-mobile-web-app-title "Euphoria"). Cache service worker berganti otomatis tiap export.
- Story Links (`DB.LINKS`, 16 link, mencakup ke-27 hero): pasangan/trio dari cerita memberi bonus stat bila semua anggota dipasang (mis. Dragon Sisters ATK +8%, The Last Light semua stat +6%). Tombol "♥ LINKS n" di Battle Prep, banner LINKS di awal battle, panel STORY LINKS di halaman hero.

## 2aa. Update batch 27 — Tampilan & animasi battle

- Kamera lebih dekat: papan battle lebih tinggi (`GridBoard.max_aspect` 0.6 di battle) dan lebih lebar; unit ±45% lebih besar, tidak terpotong di tepi.
- Banner skill baru: wajah hero + ikon elemen + nama hero kecil + nama skill besar, warna panel mengikuti elemen, animasi pop-in.
- Angka damage: lebih besar, melompat melengkung lalu memudar, ditumpuk per unit (tidak saling menimpa); crit = angka emas besar dengan "!" + label CRITICAL; teks status (SHIELD/TAUNT/ATK▲) pindah ke dekat kaki unit.
- Hit-stop 0,09 dtk saat crit (dengan pengaman reset `Engine.time_scale` saat keluar battle; dinonaktifkan oleh Reduce Effects).
- Panel "n HITS + total damage" (menghitung naik) untuk skill yang mengenai ≥2 target.
- Partikel atmosfer per medan (salju, bara, daun, gelembung, cahaya, kelopak) di belakang papan.
- Banner pembuka (synergy/field/links/tactic) lebih kecil, di atas papan, dan lebih singkat (1,1 dtk).

## 2ab. Perbaikan ikon "Add to Home Screen" iPhone

- Penyebab: server lokal memakai sertifikat HTTPS self-signed. iOS mengambil ikon home screen lewat proses sistem terpisah yang tidak mempercayai sertifikat itu → ikon gagal dimuat (log server: file ikon terkirim 200 ke Safari, tetapi ikon tidak terpakai; `/apple-touch-icon.png` di root 404).
- Perbaikan: ikon 180 px kini ditanam langsung di HTML sebagai data URI (`html/head_include`), plus file `apple-touch-icon.png`, `apple-touch-icon-precomposed.png`, `favicon.ico` di root folder builds.
- WAJIB setelah setiap export Web: `zsh tools/web_postexport.sh` (menyalin ikon root & menghapus link ikon bawaan Godot yang menunjuk file).

## 2ac. Update batch 28 — Peta baru: Arc 5 + Boss Hunt

Peta baru di `backround image/`: space, alien planet, blackhole, big tree world, kolam renang (pool), black market.
- Arc 5 "The Starbound Expedition" (Chapter 19–22, total 132 stage): Starport Horizon (space), Mycelia the Spore World (alien), Event Horizon (blackhole), Crown of Yggdrasil (bigtree). Noctis meneruskan sinyal darurat bintang-bintang lain; menara Xylia menjadi starport; bos final = wujud asli Ygg-Naar (Mata Yggdrasil) yang "meminum" bintang demi pohon dunia — diselesaikan dengan memberi bintang baru. Varian bos baru "ASTRAL" (pendar emas). 3 pilihan dialog baru. Interlude 5 "Poolside Holiday" (peta kolam renang).
- Boss Hunt (Menu, Player Lv.12): 4 target astral — Starport Behemoth (gear/SSR), Spore Queen (rune), Singularity Wraith (shard hero), Canopy Nine-Tail (gold/EXP) — 4 kesulitan NORMAL/HARD/NIGHTMARE/ABYSS, 3 perburuan/hari (kalah = tidak terpakai), kelemahan elemen +30% ATK, Hunt Core + first-clear gems.
- Hunter's Exchange (latar Black Market, Lulu): SSR Weapon/Armor/Accessory, Rune Chest, Celestial Gem, Summon Ticket, EXP Potion — stok mingguan.
- Tab BLACK MARKET di Shop kini memakai latar Black Market. Festival Juli–Agustus memakai latar kolam renang.
- 6 latar lobby baru (Poolside Resort, Night Market, Starport, Mycelia, Event Horizon, Yggdrasil).
- Achievement Arc 5; gelar "Starbound Commander" & "Apex Hunter" (menang ABYSS).
- Balance (tim endgame): bos Arc 5 Lv.70 20–35%, Lv.75 35–80%, Lv.80 50–100%; ABYSS Hunt ±12–56% di Lv.70, 100% di Lv.80 (`tools/hunt_balance_test.gd`).

## 2ad. Update batch 29 — Daily Board, Sweep Hunt, build lebih kecil

- Today's Board (ketuk cincin "TODAY" di lobby): semua aktivitas harian dalam satu daftar — misi, login, AFK, free summon, mail, daily talk, dungeon, arena, world boss, boss hunt, expedition, festival wish, guild, heart catch — dengan sisa jatah dan tombol GO/CLAIM; yang selesai ditandai ✓ di bawah.
- Boss Hunt: tombol SWEEP untuk kesulitan yang sudah dimenangkan (memakai 1 jatah, hadiah langsung).
- Build web 66,7 MB → 54,2 MB: 6 peta baru diimpor lossy (WebP 0,85) alih-alih lossless; logo sumber di root dikecualikan dari export.

## 2ae. Update batch 30 — FIX macet setelah World Boss/Raid, Arc 6, Limit Break

- BUG FIX: setelah battle World Boss / Guild Raid, tombol CONTINUE tidak bereaksi (game macet). Penyebab: popup hasil ditandai `no_back`, dan CONTINUE memanggil `main.back()` yang berhenti di popup itu. Kini CONTINUE menutup popup lalu kembali (`battle.gd _leave_result`). Diverifikasi dengan menekan tombol CONTINUE di shot_runner (`pressok`).
- Arc 6 "Echoes of the First Oath" (Chapter 23–26, total 156 stage): asal-usul Commander — reinkarnasi First Commander; para hero adalah reinkarnasi pahlawan Oath Pertama; Lucidria satu-satunya yang tidak pernah terlahir kembali dan menunggu seribu tahun. Bos "Echo" (sepia pudar): Echo of Sven, Hyeonxa, Siv (penempa Oath Ring), Lucidria. Ending: Second Oath. 4 pilihan dialog. Interlude 6 "Pressed Flowers".
- Limit Break (tab UPGRADE, hero 6★ di level maks): +5 batas level per tahap, 4 tahap → Lv.100. Biaya: Hunt Core, shard, Gold.
- Gelar: "Keeper of the Second Oath", "Limitless". Achievement Clear Arc 6.
- Balance bos Arc 6 (tim endgame): Lv.80 0–20%, Lv.90 45–80%, Lv.100 70–100% — dirancang untuk Limit Break.

## 2af. Update batch 31 — Starlight Rift + smoke test otomatis

- Starlight Rift (Menu, Player Lv.15): mode roguelite mingguan. Daki lantai; setiap menang pilih 1 dari 3 Blessing (R/SR/SSR: ATK/HP/DEF, elemen +20%, Glass Cannon, Starlight Crown, dll.) yang menumpuk sepanjang run; setiap lantai ke-5 bos hero varian acak (Mirror/Hollow/Astral/Echo); latar berganti tiap 5 lantai melewati 10 peta; kalah = run selesai (lantai terbaik tersimpan). Hadiah tahap lantai 5–50 (gems, Hunt Core, tiket, Celestial Gem, Oath Ring) dan peringkat [AI] mingguan.
- Balance (`tools/rift_balance_test.gd`): rata-rata lantai Lv.40 ≈ 21, Lv.60 ≈ 38, Lv.80 ≈ 55.
- Smoke test UI otomatis: `zsh tools/smoke.sh` — membuka 28 layar + memainkan 6 mode battle (story bos, World Boss, Boss Hunt, Rift, Dungeon, Tower) sampai CONTINUE dan memastikan kembali ke layar asal (deteksi error script & macet). Jalankan sebelum setiap rilis.

## 2ag. Update batch 32 — Peta baru: Arc 7, Private Room, 2 Boss Hunt

Peta baru di `backround image/new backround maps/` (diimpor lossy 0,85): abadon city, aphocalipse, dino, dragon fire, necro, outland, onsen, room game, room1, room2, shower.
- Arc 7 "Ashes of Abaddon" (Chapter 27–30, total 180 stage) — kisah asal Abadonia: Abaddon City (kerajaannya yang hancur 300 tahun lalu), Primeval Vale (dino), Necropolis of Kings, Abaddon Burning (apocalypse). Kakaknya, Pangeran Aurelion, membuat perjanjian dengan Eclipse; bos final Ashen Abadonia (rasa bersalahnya). Varian bos baru "ASHEN" (kelabu + bara). 4 pilihan dialog. Interlude 7 "Lion's Onsen".
- Private Room (Menu, Player Lv.3): 5 ruangan — Commander's Room (game room), Cozy Bedroom, Dragon Bedroom, Moonlit Onsen, Bathhouse — terbuka per Bond tertinggi (1/3/5/7/9). Undang hero: TALK (5x/hari, +Bond, x2 di ruangan favorit hero), REST TOGETHER (+20 energi, 1x per ruangan per hari), hadiah, SET AS LOBBY.
- Boss Hunt +2: Cinder Witch of Dragonbone (dragon fire; Star Stone) dan Outland Leviathan (outland; Hunt Core ekstra). Daftar Hunt kini bisa digulir.
- Starlight Rift: 16 peta, varian bos + Ashen. 10 latar lobby baru.
- Gelar: "Hero of Abaddon", "Homebody". Balance bos Arc 7: Lv.90 10–70%, Lv.100 50–100%.

## 2ah. Update batch 33 — Tutorial fitur baru, NOTICES, Hero Trials

- Tutorial ringkas untuk World Boss, Boss Hunt, Starlight Rift, Private Room, Festival, Commander Tactics, Limit Break (muncul sekali saat pertama dibuka).
- NOTICES (tombol kiri lobby + badge jumlah belum dibaca): papan pengumuman dengan banner peta. Isi diedit di `data/news.json` (id, date, tag UPDATE/NEW/EVENT/INFO, title, bg, body).
- Hero Trials (tab INFO hero yang dimiliki): 3 tingkat (Lv.18/45/78); bos = Mirror hero itu sendiri + musuh berelemen yang mengalahkannya; syarat: hero itu dipasang DAN bertahan hidup. Hadiah first clear: shard hero (10/15/25), gems, gold/Star Stone, +50 Bond. Gelar "Mirror Master" (30 tingkat).
- Smoke test kini juga mencakup Hero Trial dan NOTICES.

## 2ai. Update batch 34 — Facelift UI (setara Sakura Oath / Brown Dust)

- UI kit bertekstur prosedural (`tools/gen_ui_kit.py` → `art/ui/*.png`, 9-slice; bisa diganti art dari artist dengan nama & ukuran sama): panel gradien + garis emas ganda + ornamen sudut, kartu, popup berornamen + pita judul (RibbonPanel), tombol emas mengilap (normal/hover/pressed/disabled), tombol & tab ungu dengan kilau, header layar bergaris emas bercahaya, bilah navigasi bawah, medali Story bercahaya.
- Dipasang di tema global (`UI.theme()` via `UI.tex_box`) → semua layar berubah sekaligus; fallback otomatis ke gaya datar bila PNG tidak ada.
- Kartu hero: bingkai rarity (SSR emas berornamen + permata, SR ungu, R biru) + kilau hologram bergerak pada SSR yang dimiliki (mati bila Reduce Effects).
- Layar VICTORY: sinar cahaya berputar di belakang MVP + lambang bersayap di atas judul.
- Summon: panel info kini bisa digulir (tidak lagi tertimpa tombol).

## 2aj. Update batch 35 — Scroll gaya galeri, tombol HOME, layout, Secretary Moment

- Scroll gaya galeri HP (`game/ui/drag_scroll.gd`, dipakai oleh semua `UI.scroll`): geser di mana saja di dalam daftar — termasuk di atas tombol/kartu — dengan inertia. Ketukan biasa tetap menekan tombol; begitu jari bergeser > 8 px di sumbu scroll, tombol di bawah jari direset sehingga tidak terpicu. Geseran di sumbu lain (drag & drop hero ke papan) tetap berfungsi. Diuji dengan simulasi jari (`drag:` di shot_runner).
- Tombol HOME (ikon rumah) di header semua layar fitur → langsung ke lobby. Battle tidak memakai header, jadi pertarungan tidak terganggu.
- Panel besar bergaris emas (peta Story, info Summon, kartu lobby, dll.) otomatis memakai bingkai berornamen; deretan tab ARC/Chapter di Story kini bisa digeser.
- Secretary Moment (ala Sakura Oath): sekali sehari hati berdenyut muncul di samping hero lobby → adegan singkat layar penuh + pilihan jawaban + Bond + hadiah kecil (7 momen; CG opsional `art/cg/<hero>_moment.png`).

## 2ak. Update batch 36 — NPC toko beranimasi (rig titik tumpu) + layar loading web

- Lulu (Black Market Night Shift & Hunter's Exchange) kini beranimasi dari `Karakter Euphoria Online/npc/Store Character.jpg` (latar dibuang → `art/npc/store_lulu.png`).
- Rig titik tumpu (`game/ui/npc_rig.gdshader` + `game/ui/npc_puppet.gd`): kepala miring di pangkal leher, tubuh atas condong di pusat pinggul, napas di dada, tangan di dada naik-turun, ujung rambut bergoyang, kedip acak (kadang dua kali), mulut bergerak selama durasi klip suara + angguk saat bicara, pipi merona. Titik tumpu diukur dari lembar "Titik Tumpu (Pivot Point)" dan bisa diatur lewat uniform shader.
- Zona sentuh: kepala / badan / kaki — masing-masing suara & reaksi sendiri. Menyapa, berterima kasih (lompat + merona), sedih bila uang kurang, menyapa sendiri bila lama didiamkan. 6 kategori suara baru untuk `shop2` (TTS; ganti file `audio/voice/shop2_*.wav` untuk voice actor).
- FIX: gelembung bicara berlatar terang sempat berubah gelap (aturan bingkai otomatis) → teks tidak terbaca; kini panel terang dikecualikan.
- Layar loading web (`web_shell/euphoria_shell.html`, cadangan `euphoria_shell_backup_v1.html`): tema ungu-emas, persentase besar, tips gameplay bergilir tiap 4 dtk.

## 2al. Update batch 37 — Event berganti otomatis + Merchant Lulu beranimasi

- 5 event terbatas bergiliran tiap 14 hari (`DB.EVENTS`, `DB.EVENT` = event aktif via `DB.set_event_period`): Moonlit Festival (Lumeira, aqua), Primeval Safari (Atalanta, dino), Necro Masquerade (Vexira, necro), Starport Gala (Gemora, space), Dragonbone Trials (Zennyo, dragonfire). Masing-masing: 5 stage + bos, exchange dengan shard hero unggulan, cerita pembuka (kunjungan pertama) & penutup (setelah bos kalah). Mata uang kini "Event Token".
- Merchant of Euphoria Lulu (tab toko biasa) kini juga NPCPuppet dengan titik tumpu sendiri (`SHOP1_PIVOTS`) + 6 kategori suara baru `shop1_*`.
- NPCPuppet menerima `pivot_overrides` sehingga rig bisa dipakai karakter lain.

## 2am. Update batch 38 — 5 hero + 3 musuh (4 Nov), banner Special Event, NPC lobby Hairly

- Import `tools/import_nov4.py` (sumber sudah transparan → crop + resize; file "…a" = ekspresi alternatif, `_loby` dari `npc/new npc 4 nov` = pose lobby).
- Hero: Angela (SSR LIGHT Paladin, buff ATK tim + taunt), Kara (SSR FIRE Assassin, 220% + burn), Mei (SSR FIRE Warrior, 2x2 + DEF down), Ning Er (SR EARTH Healer, heal + cleanse), Spimei (SR FIRE Ranger, semua musuh + burn). Suara 8 kategori, 3 Memory, profil (`tools/hero_content_nov4.py`), 5 Story Link baru. Total 32 hero.
- Musuh: Hairly (DARK mage, silence), Svormentis (WATER tank, drain), Ymir (EARTH warrior, stun) — di Arc 7, event Necro Masquerade/Starport Gala, Rift, dan World Boss (Ymir, Svormentis).
- Banner Special Event (`art/banners_event/`): Mei (3 frame — ketuk = animasi 1→2→3 seperti GIF, di Summon & tampilan besar dari lobby), Kara, Sven (pick-up R), Zennyo. Rate-up kini berlaku untuk rarity hero unggulan (R/SR/SSR).
- Pose lobby & ekspresi alternatif: hero sekretaris memakai pose lobby (`DB.lobby_art`); menyentuh hero menampilkan ekspresi "a" sesaat (`DB.alt_art`, `UI.flash_expression`).
- Hairly's Fortune (tombol FORTUNE di lobby): Hairly beranimasi (NPCPuppet, `DB.HAIRLY_PIVOTS` dari lembar titik tumpu), 9 suara, satu kartu tarot per hari dengan hadiah.
- Daftar banner di Summon kini bisa digulir.
- Semua aset baru diimpor lossy (WebP 0,85) — build 69 MB (sempat 104 MB saat lossless).

## 2an. Update batch 39 — Grafity & Hairly sebagai penjaga toko beranimasi

- Grafity (`art/npc/grafity_shop.png` dari `npc/new npc 4 nov/Grafity_loby.png`) dengan titik tumpu dari lembar rigging-nya (`DB.GRAFITY_PIVOTS`): napas, kepala, rambut panjang bergoyang, kedip, mulut bicara, merona + fitur baru shader: 6 api roh hijau berkedip & bergetar (`flames[]`, `flame_color`, `flame_time` di `npc_rig.gdshader`). 9 suara tsundere (`grafity_*`).
- Toko kini punya 4 penjaga beranimasi per tab (`shop.gd TAB_KEEPER`): Gem/Gold → Lulu Merchant, Arena → Hairly (Champion's Oracle), Friend → Grafity (Friendship Corner), Black Market → Lulu Night Shift. Hanya penjaga aktif yang beranimasi (hemat performa).

## 2ao. Update batch 40 — Arc 8 "The Gilded Gate" + Bestiary

- Arc 8 (Chapter 31–34, total 204 stage) memperkenalkan 5 hero 4 November: The Gilded Gate (Angela; bos Hairly → menjadi peramal Commander), Thousand-Coin Bazaar (Ning Er; bos Svormentis), Crimson Dojo (Mei & Kara; bos Ymir), Scarlet Engine (Spimei; bos Mirror Spimei tanpa hati). 4 pilihan dialog. Interlude 8 "Five New Faces". Achievement Clear Arc 8.
- Balance bos Arc 8 (tim endgame): Lv.90 10–70%, Lv.100 45–100%.
- Bestiary (Menu, Player Lv.2): semua jenis musuh tercatat saat dikalahkan (battle biasa & Auto-Repeat); siluet "???" untuk yang belum ditemui; detail elemen/peran/skill/jumlah kalah; 4 milestone per musuh (10/50/150/400 → gems, gold, tiket, Celestial Gem).

## 2ap. Update batch 41 — Date (kencan) + FIX dialog selesai ganda

- Date (Menu, Player Lv.4): ajak hero Bond ≥3 ke 6 lokasi (Whispering Woods, Poolside Resort, Moonlit Onsen, Night Market, Starport, Yggdrasil; terbuka per progres story). Adegan 3 momen × 3 pilihan; jawaban sesuai selera hero (`DB.liking`) memberi Bond terbanyak → PERFECT / SWEET / NICE DATE + bonus Bond + gems. Foto kenangan (latar + hero, bingkai warna peringkat) tersimpan di DATE ALBUM (maks 60). 2 kencan/hari. Data di `DB.DATE_SPOTS` (mudah ditambah).
- BUG FIX penting: ketukan selama fade-out di akhir dialog VN memanggil `_finish` berulang → callback penutup (hadiah kencan/interlude/epilog dll.) bisa terpicu berkali-kali. Kini `VNDialogue._finish` hanya sekali dan input diabaikan setelahnya.

## 2aq. Update batch 42 — Merapikan menu + Commander Road

- MENU dikelompokkan (`DB.MENU_SECTIONS`): BATTLE, EVENTS, HEROES & BOND, SHOP & SOCIAL; ubin lebih kecil, 6 kolom, bisa digulir (sebelumnya meluap keluar layar). Ikon baru untuk Date/Private Room/Garden (sebelumnya 3 hati kembar), Bestiary ikon sendiri.
- Lobby: kolom kiri tinggal Mail, Missions, Login, Notices (Event & Festival pindah ke MENU + slide banner Festival di carousel); tombol TALK/OUTFIT/SCENE/FORTUNE jadi satu baris sejajar di bawah hero.
- Formation: Tactics Guide bisa digulir dan tidak lagi menimpa panel bawah. Heroes: header muat (tombol Sort tidak terpotong).
- Commander Road (tab baru di Missions): hadiah tiap 5 level Commander (Lv.5–100), hadiah GRAND tiap 25 level (Celestial Gem + tiket); termasuk dalam CLAIM ALL dan badge Missions.

## 2ar. Update batch 43 — Special Skins & Wardrobe

- 6 skin spesial (`*_char_evo_special.png`) diimpor sebagai state "special" (`tools/import_special_skins.py`; latar putih Lucidria/Hyeonxa/Kali dibuang — diratakan ke putih dulu agar margin transparan tidak jadi hitam): Infernal Morningstar (Lucidria), Crimson Hydra Bloom (Hyeonxa), Moonlit Hundred Blades (Kali), Night Wolf Empress (Abadonia), Golden Jackpot (Ning Er), Scarlet Overdrive (Spimei).
- Eksklusif: tidak terbuka lewat Star/Bond/Oath; hanya lewat WARDROBE (Menu › Shop & Social, slide banner lobby) dengan Special Skin Ticket atau 1.280 Gems. Selalu memberi bonus outfit tertinggi (+10% ATK & HP). Saat dipakai sekretaris → percikan emas di lobby. Di tab Outfits: tombol "WARDROBE ▶".
- Skin Ticket: hadiah mail "Special Skins Have Arrived!" + Commander Road Lv.50 & Lv.100.
- FIX tools: `import_new_heroes.py` kini dijaga `if __name__ == '__main__'` (sebelumnya meng-import fungsinya menjalankan ulang seluruh import lama).

## 2as. Update batch 44 — Efek battle & gestur lobby

- Kematian unit: shader dissolve (`game/ui/dissolve.gdshader`) — terbakar dari bawah ke atas dengan tepian cahaya warna elemen penyerang (fallback fade bila Reduce Effects). Revive membersihkan shader.
- Ancang-ancang: unit membungkuk (squash) sebelum setiap serangan (`UnitView.wind_up`).
- FINISH!: musuh terakhir tumbang → gerak lambat 0,35×, punch-in kamera, kilat putih, gelombang warna elemen, teks besar (sekali per battle).
- Gestur lobby (`lobby.gd _gesture`): ketuk = zona sentuh lama; usap kepala = head-pat beruntun (hati, hero condong, lalu bicara + Bond); tekan lama 0,75 dtk = close-up (zoom ke wajah 2 dtk); geser kiri/kanan = ganti hero sekretaris dengan animasi slide.

## 2at. Update batch 45 — Animasi Summon baru

- Gerbang: latar langit berbintang (galaxy) muncul perlahan, dua lingkaran sihir bercahaya (additive) berputar berlawanan arah, partikel cahaya berwarna rarity berkumpul.
- Kartu: punggung kartu berornamen (`art/ui/card_back.png`, dari `tools/gen_ui_kit.py`) muncul satu per satu dengan pop; tanda rarity sebelum dibuka — SR berpendar ungu, SSR berpendar emas.
- Splash SSR: kilat putih, sinar emas berputar, percikan emas, artwork hero "live" yang zoom-in dari dekat, nama hero menghentak (scale 1,8→1).

## 2au. Update batch 46 — Hero Luby + 5 musuh (4 Nov part 2)

- Import `tools/import_nov4b.py` (memakai helper `import_nov4.py`). FIX importer: huruf a–e setelah angka (mis. `evo3b`) = ekspresi alternatif; file `*special*` tidak dihitung sebagai outfit.
- Hero Luby (SSR WIND Assassin, Mecha-Cat Pounce: cross 140% + stun + crit): 5 outfit, 3 ekspresi alternatif, skin spesial "Plush Panther Purr" di Wardrobe, banner rate-up, suara (8), 3 Memory, profil, Story Link "Mischief & Machines" (Luby + Micca). Total 33 hero.
- Musuh: Scomantis (WIND assassin, burn), Skelinch (FIRE warrior, pierce+burn), Serpentia (FIRE mage, 2x2+burn), Voodoo Doll (DARK assassin, DEF down), Liza Morph (DARK tank, silence). Dipakai di Arc 4/7/8, event Primeval Safari/Necro Masquerade/Dragonbone Trials, Rift, dan World Boss (Serpentia).

## 2av. Update batch 47 — SSR Ultimate & gestur halaman hero

- Battle: `battle.gd _ultimate(u)` — hero SSR milik pemain memutar cut-in layar penuh sekali per battle saat skill pertamanya: langit warna elemen, garis kecepatan (draw callback), pita miring, ilustrasi penuh (skin yang dipakai) meluncur masuk, "✦ ULTIMATE ✦" + nama skill menghentak, suara skill, kilat putih. Dilewati jika skip/speed >2/reduce_fx/skip_cutin. Cut-in biasa diberi garis cahaya atas-bawah.
- Hero Detail: `_gesture` — tap = reaksi lama; usap kepala = head-pat (hati, condong, +6 Bond & ekspresi alternatif setelah usapan panjang); tekan lama 0,75 dtk = close-up (zoom `_holder`); geser horizontal = hero sebelum/berikutnya dengan slide-in (`params.swipe`).
- shot_runner: parameter layar mendukung daftar `a;b;c`.

## 2aw. Update batch 48 — Upacara Oath

- `game/ui/oath_ceremony.gd` (OathCeremony, di `main.overlay`): aula surgawi (asgard) + kelopak, cincin Oath digambar prosedural (berputar semu-3D, halo, berkas cahaya, permata berkilau) dengan teks sumpah → bloom putih → hero dengan outfit Oath + sinar emas berputar, "OATH SWORN", "Bound on <tanggal>", bonus. Tap untuk lanjut (atau melewati tahap cincin), lalu dialog sumpah seperti sebelumnya.
- `Game.swear_oath` menyimpan `oath_date`; `Game.oath_date(id)` ("5 Nov 2026"; save lama → "a day to remember").
- Tab BOND: tanggal sumpah + tombol "REPLAY CEREMONY".
- shot_runner: langkah `oath:<id>` (Bond max + cincin + sumpah + upacara).

## 2ax. Update batch 49 — 2.5D Live: Glytta evo2

- Sumber: lembar pivot `Karakter Euphoria Online/hero/Glytta/glytta_char_evo2_3d.png` (dipakai sebagai referensi posisi bagian; potongannya terlalu kecil ±100 px untuk dirakit langsung, jadi rig diterapkan ke artwork asli 1920×2240).
- `tools/make_depth_glytta.py` → `glytta_char_evo2_depth.png` (siluet gadis = dekat, maw kiri di depan pinggang, kepala beast/mata besar = tengah, asap = jauh, + volume bulge). `tools/make_depth.py` = versi heuristik otomatis (kurang akurat, cadangan).
- `game/ui/live25d.gdshader`: parallax kedalaman (3 iterasi), napas dada, kepala miring di leher, construct bergelombang, halo naik-turun, pupil mata besar membesar-mengecil, mulut terengah, kedip acak (kadang dua kali), api/mata biru berdenyut, cahaya 3D dari kemiringan depth mengikuti tilt.
- `game/ui/live_rig.gd` (LiveRig): dipasang otomatis oleh `UI.live`; jika tekstur ada di `DB.LIVE_RIGS` (evo2 + ekspresi evo2_a) → shader 2.5D, selain itu shader live biasa. Tilt mengikuti kursor (desktop) / jari saat menyentuh (HP), orbit pelan saat diam. Berlaku di lobby, detail hero, Private Room, Date, dll.
- Menambah hero lain: buat depth map + entri di `DB.LIVE_RIGS` (pivot UV).

## 2ay. Update batch 50 — Gallery per hero, Taming, pinch zoom, potong ulang artwork

- Gallery: satu kartu (portrait) per hero, dikelompokkan SSR → SR → R, progres outfit; klik → popup album semua stage/evo/skin spesial (label "Stage N / Evolution N / ✦ skin"), viewer layar penuh dengan pinch/double-tap/drag. Hanya ±33 tekstur dimuat di daftar.
- Heroes: 6 kolom, ukuran kartu mengikuti lebar.
- Lobby: TALK/OUTFIT/SCENE/FORTUNE jadi pil kecil semi-transparan di atas area sentuh (sebelumnya tertutup tombol sentuh hero transparan → tidak bisa diklik); area sentuh dipendekkan (anchor_bottom 0.7).
- `game/ui/pinch_zoom.gd` (PinchZoom): deteksi dua jari (ScreenTouch/Drag), trackpad magnify, Ctrl+wheel; `active()` untuk mencegah bentrok dengan tap. Dipakai di Gallery viewer, Hero Detail (zoom `_holder` di titik jari; saat ter-zoom: seret = geser gambar, tap = interaksi, swipe/long-press nonaktif), Bestiary.
- Bestiary: strip bentuk (LV/EVO) di bawah artwork; bentuk terbuka lewat kills (`DB.FORM_KILLS`) atau Bond jinak (`DB.FORM_BOND`); tap = reaksi (goyang/gemetar/lompat), usap kepala = elus (musuh jinak), tab INFO / TAMING.
- Taming: `DB.TAME_KILLS` 20 + `DB.TAME_GOLD` 10.000; `Game.tame / pet / pet_talk (1/hari) / pet_pat (5/hari) / pet_gift / pet_add_exp / form_unlocked`; Bond 1–10 (`DB.pet_bond_next`), hadiah Lv.3/5/7/10 (`DB.PET_REWARDS`); dialog kepribadian 15 musuh di `DB.PET_LINES`. Save: `s["tamed"]`.
- Potong ulang artwork: `tools/recut.py` (rembg isnet-anime + kunci warna latar apa pun + de-fringe) dan `tools/recut_all.py` (pasangan sumber→art lewat nama, urutan importer `import_new_heroes`, MANUAL untuk Ygg-Naar/Ex-Nymph, fallback kemiripan; verifikasi kemiripan; ukuran maksimum mengikuti art lama; sumber PNG transparan dilewati). Cadangan file lama: `_recut_backup/` (+ log.json, run.log, fix.log; ada `.gdignore` agar tidak ikut export). Latar kotak-kotak "transparan palsu" (Scylla, Slime) dideteksi `checker_colors` (dicek sebelum warna latar polos). Pemeriksaan kedua `tools/recut_fix_mismatch.py` (template matching multi-skala). PENTING: setelah pemulihan, banyak `.import` kembali lossless/tanpa batas — standar: char `size_limit=1200`, sprite `size_limit=512`, `compress/mode=1` lossy 0.85; piksel alpha<12 dinolkan. pck 87 MB. Penyebab kerusakan lama: flood-fill putih + `clean_white_holes` memakan rambut putih/kulit pucat/efek cahaya.

## 2az. Update batch 51 — Companion

- `Game.companion() / set_companion() / companion_bonus()` (save `s["companion"]`, hanya musuh jinak); bonus `DB.COMPANION_PER_BOND` 0,005 × Bond ke ATK & HP semua hero lewat `stat_bonus` (maks +5%).
- `game/ui/companion_cameo.gd` (CompanionCameo): chibi memantul + label nama; `cheer()`; mode interaktif (lobby) → kalimat + elus harian (`pet_pat`) + hati.
- Lobby: cameo di samping sekretaris (anchor 0.43, di atas pil aksi); `_say(text, who)` sekarang menerima nama pembicara.
- Battle: cameo di pojok kiri bawah, baris intro "COMPANION: … +x% team ATK/HP" dan lompatan sorak.
- Bestiary tab TAMING: tombol SET AS COMPANION / ★ COMPANION.

## 2ba. Update batch 52 — Companion Assist & Bond Stories musuh jinak

- `BattleSim.companion` ({id, bond}) + `_companion_round`: ronde 2, damage ke semua musuh (0,45 + 0,05×Bond) × rata-rata ATK tim, lalu efek skill musuh itu (burn / DEF▼ / stun 60% peluang / silence). Event `companion` diputar `battle._play_companion` (teks "X ASSIST!", sprite menerjang, damage + status + efek elemen, die dengan warna elemen). Juga dipakai `Game.quick_battle` (sweep) lewat `Game.companion_assist()`.
- Bond Stories: `DB.PET_STORY_REQ` [3,6,10], `PET_STORY_TITLES`, `PET_STORY_REWARDS`, `DB.pet_story(id, ep)` (template dari kepribadian `PET_LINES` + gelar); `Game.pet_story_state / read_pet_story / pet_stories_ready`; save `pet.stories`. UI di tab TAMING (READ / REPLAY / 🔒) + tanda ♥ di grid Bestiary.

## 2bb. Update batch 53 — Arc 9: The Wild Hunt

- Bab 35–38 (228 stage): Howling Wilds (outland, boss Scomantis), Serpent Springs (pool, Serpentia), The Puppet Fair (necro, Voodoo Doll), The Last Hunt (blackhole, boss Feral Luby). Tema: Tanduk Perburuan membuat hewan jinak jadi liar; kisah ditutup dengan semua hewan jinak berdiri bersama Commander; Liza Morph (bayangan pemakan ikatan) menjadi tamu.
- Varian baru `feral` (desat 0,5 + cahaya merah darah) di UI.corrupt, VN (`feral:` speaker), DB.base_id/name_of ("Feral X")/theme_color.
- Interlude 9 "Bath Night for Beasts" (onsen, req 228); misi `ch38`.
- Story: tab ARC 9, `_arc_name` ≥34.
- Balance (BONUS 0,4; tim fidelia/shina/lucidria/rumi/furu) Lv90/95/100: 35-6 40/80/90%, 36-6 45/50/50%, 37-6 30/30/45%, 38-6 10/30/45%. Catatan: pool berisi 3 assassin + field elemen yang sama = 0% — campur kelas musuh.
- FIX: `LiveRig` dulu mengembalikan shader live setiap tekstur berganti → efek mirror/hollow/echo/ashen hilang di adegan VN. Sekarang hanya mengganti material miliknya; `UI.live` memanggil `LiveRig.set_live` bila dipanggil ulang.

## 2bc. Update batch 54 — 2.5D Live untuk semua hero

- `tools/make_depth_auto.py`: depth "bantal" dari siluet (distance transform → sqrt, sedikit condong atas-depan), 320 px tinggi → `art/depth/<nama>_depth.png` (216 file, 4,1 MB). Jalankan ulang setelah menambah/memotong ulang artwork hero.
- `live25d.gdshader` uniform `generic`: hanya parallax + napas + cahaya 3D (kepala/mata/mulut/halo/cahaya biru khusus rig manual).
- `DB.live_rig`: rig manual (`LIVE_RIGS`) dulu, lalu otomatis untuk tekstur di `/heroes/` bila depth ada (strength 0,011); cache `_auto_rig`.
- `LiveRig` reset `generic`/`strength` tiap ganti tekstur; menghormati `settings.live25d` (Settings: "2.5D Live art", default ON).

## 2bd. Update batch 55 — 2.5D Live untuk semua musuh + varian

- `make_depth_auto.py` juga memproses `art/characters/enemies/*/char` (277 depth, 6,1 MB). `DB.live_rig` menerima `/heroes/` dan `/enemies/`.
- `live25d.gdshader`: `corrupt_on`, `hue_shift`, `desat`, `variant_glow` (port dari corrupt.gdshader) → musuh/karakter varian tetap 2.5D.
- `UI.corrupt` menyimpan meta `corrupt_params` + memasang LiveRig; `UI.live` menghapus meta itu. `LiveRig` mereset parameter varian ke default lalu menerapkan meta.
- UI.live ditambahkan: Bestiary, MVP layar kemenangan, banner Event, boss Guild Raid, popup perayaan upgrade, viewer Gallery.
- shot_runner: langkah `matprobe` (cetak shader tiap art live di layar).

## 2be. Update batch 56 — Photo Studio

- `game/screens/photo.gd` (route "photo", menu HEROES & BOND, unlock Lv.2, tutorial "photo"): panggung (latar dari `DB.BG`, hero 2.5D bisa digeser/pinch/wheel/flip, Companion opsional), filter `FILTERS` lewat `game/ui/photo_grade.gdshader` (screen texture: tint/saturasi/kontras/sepia/vignette/bloom), bingkai `FRAMES` (Gold/Polaroid+tanggal/Film/Hearts), keterangan.
- SNAP: sembunyikan panel+header, `frame_post_draw`, `get_viewport().get_texture().get_image()` → `user://photos/photo_<ms>.png` (maks 30, terlama dihapus), `stats.photos`; popup hasil; web: unduh via `JavaScriptBridge` (data URI). Album popup (grid, lihat/hapus).
- smoke.sh: layar `photo` ditambahkan.

## 2bf. Update batch 57 — Grafik battle: cahaya unit, bayangan lembut, latar hidup

- `game/ui/unit_light.gdshader`: normal dari kemiringan alpha (2 radius) → rim light di tepi yang menghadap cahaya (kiri-atas), bayangan di sisi lain, AO di kaki; `ambient` per peta. Dipasang ke sprite unit non-elite (`battle._unit_light`, satu material per battle; warna dari `battle.LIGHT` per kunci latar).
- `UnitView`: bayangan kontak = GradientTexture2D radial (cache statis) menggantikan Panel elips.
- `battle._living_bg`: latar bergerak pelan (scale 1,03↔1,07 + geser ±18 px, 9 dtk), berkas cahaya additive di peta terang; nonaktif saat reduce_fx.

## 2bg. Update batch 58 — Efek skill per bentuk area

- `SkillFX`: `meteor` (jatuh dengan ekor + burst + debris), `slash` (bulan sabit 4 lapis + garis putih), `debris` (serpihan dengan gravitasi), `vortex` (3 lengan spiral).
- `battle._skill_fx`: square → hujan meteor; cross/x → dua tebasan menyilang + debris; all → gelombang + vortex (WIND/DARK/CHAOS/WATER) atau hujan meteor (FIRE/EARTH/LIGHT/LIGHTNING); melee single → tebasan; target utama → debris.

## 2bh. Pemulihan skin spesial Wardrobe

- 7 skin Wardrobe (lucidria, hyeonxa, kali, abadonia, ninger, spimei, luby) sekarang = salinan persis file sumber di `Karakter Euphoria Online` (tanpa crop/resize/alpha), cadangan lama di `_recut_backup/special_before_restore/`.
- Sumber hyeonxa/lucidria/abadonia/kali diubah 5 Nov 13:51–13:52 dan sudah rusak (Abadonia tanpa kepala, tubuh tembus); tidak ada salinan asli di komputer (dicek folder aset utama `/Users/apple/Documents/character/aset character utama`, Downloads, build 13:37). Perlu file asli dari pengguna.
- Asli Xylia (`hero/devil/devil_char_special.jpg`, `devil_Sprite_Special.jpg`) & Micca (`Micca Pandora/Special Skin`) ada di folder aset utama.

## 2bi. Update batch 59 — Gear Sets

- `DB.GEAR_SETS` (inferno/tidal/aegis/swift/vampire), `DB.gear_set(g)` (gear lama: set dari `uid % 5`, tanpa migrasi), `Game.add_gear` memberi set acak, `Game.gear_set_counts(id)`.
- `Game.stat_bonus`: bonus 2 gear ditambahkan setelah bonus datar; `b["sets"]` = set 3 gear (dibawa lewat `ally_team` → `BattleSim._make_unit` → `unit.sets`).
- BattleSim: Bastion shield 15% di setup (event `status` SHIELD, kini diputar `battle.gd` walau berdiri sendiri), Gale Fang crit ×1,3, Flame Pact burn 30% ATK bila skill tidak punya burn, Crimson Thirst lifesteal 12%, Tidecaller heal 6%/ronde di `_end_of_round`.
- UI: tab GEAR (label set per item, panel SET BONUS 2/3), popup pilih gear menampilkan set. shot_runner: `gearset:<hero>|<set>`.

Tes web di iPhone: `zsh run_iphone_server.sh`, lalu buka `https://<IP-Mac>:8443/Euphoria_v2.html` di Safari (Wi-Fi sama).

## 2bj. Update batch 60 — The Forge
- Layar baru `game/screens/forge.gd` (route "forge", menu SHOP & SOCIAL, buka di Player Lv.6) dengan 3 tab: REFORGE, FUSE, SALVAGE.
- Item baru `forge_ember`. Sumber: salvage (R 2, SR 6, SSR 20, plus 1 per 2 level enhance) dan Armory Ruins (3 x level dungeon). Biaya reforge: R 4, SR 12, SSR 30.
- FUSE: 3 gear satu rarity jadi rarity berikutnya (R ke SR 5.000 Gold, SR ke SSR 30.000 Gold). Gear utama mempertahankan slot, set, level dan pemakainya.
- Kunci gear (`g.lock`): gear terkunci tidak bisa di-salvage atau dipakai sebagai bahan fuse. Bulk salvage juga melewati gear terpakai, dan gear enhanced kecuali dicentang.
- Armory Ruins: "Today's Set" berganti harian (`DB.armory_set`), tiap clear memberi 1 gear set itu (kunci reward `gear:any:<rarity>:<set>`).
- Tab GEAR: tombol WEAR SET (`Game.auto_equip_set`, tidak mengambil dari hero lain); pilihan gear menampilkan "★ n/3"; AUTO EQUIP tidak lagi merusak set yang sedang dipakai.
- Uji set di boss Arc 9 (tim 5 hero semua set sama, bonus 0.4, 40 battle): 38-6 di Lv100 30-40% dengan set vs 32% tanpa set; 35-6 dan 36-6 naik sampai 90-100% dengan Tidecaller/Crimson Thirst. Angka set tidak diubah.

## 2bk. Update batch 61 — Gear Substats & Temper
- Tiap gear punya substat acak `g.subs` = `[{k, q, up}]`: R 1, SR 2, SSR 3, stat tidak kembar dalam satu gear. Nilai = `DB.GEAR_SUB_MAX[k]` × (0,5 + 0,5q) × (1 + 0,5·up). Masuk `Game.stat_bonus` (termasuk Crit) dan `DB.gear_score`.
- Enhance: di +5 dan +10 satu substat acak naik (`Game.last_sub_up` untuk toast). Fuse: naik rarity menambah 1 substat, yang lama tetap.
- Forge tab baru TEMPER (tutorial "temper"): `Game.temper_gear(uid, keep)` membayar Embers lalu mengembalikan hasil tanpa mengubah gear; `Game.temper_accept` menerapkannya. Popup CURRENT/NEW tidak bisa ditutup dengan back. Biaya `DB.TEMPER_COST` R 3, SR 8, SSR 20, ×2 per substat yang dikunci; minimal 1 substat harus diacak; upgrade (▲) tetap di slotnya.
- Save lama: `Game._ensure_gear_subs()` dipanggil dari `_sanitize` (load & import), mengacak sekali plus upgrade sesuai level gear. SAVE_VERSION tidak berubah.
- Hero GEAR: baris Bonus kini menampilkan Crit bila ada.
- Balance (tim bawaan, Lv90, 40 battle, bonus 0,40 lawan perkiraan rata-rata 0,44 + Crit 2,3%, artinya 15 gear SSR +10): 23-6 37→72%, 27-6 25→77%, 35-6 50→65%, 38-6 12→17%. Nilai awal (HP 3%, ATK 2,5%) ditolak karena 27-6 jadi 95%. Catatan: 29-6 dan 30-6 terlihat ~0% hanya untuk tim bawaan; formasi lain menang 76-90%, jadi bukan lonjakan kesulitan.
- Tes: smoke kini mencakup 11/11 mode battle (arena, raid, event, hard ditambahkan) dan alur TEMPER lewat tombol sungguhan; step baru `press:<awalan teks>` di shot_runner. flow_test: blok `[gear substats]`.

## 2bl. Penarikan 4 skin spesial rusak

- Skin spesial Lucidria, Hyeonxa, Kali, dan Abadonia dihapus dari game (art, depth map, `character_database.json`, `DB.SPECIAL_SKINS`, teks mail/news, slide lobby). Wardrobe kini berisi Ning Er, Spimei, Luby.
- Save lama: `Game._withdraw_skins()` mengembalikan 1 Skin Ticket per skin yang sudah dibeli, lalu hero dipindah ke outfit terbuka tertinggi. Daftarnya di `DB.WITHDRAWN_SKINS`.
- Untuk mengembalikan: art lama masih ada di riwayat git (commit `4ce50f4`), tetapi itu versi yang rusak. Bila file asli ditemukan, jalankan ulang impor lalu hapus hero terkait dari `WITHDRAWN_SKINS`.

## 2bm. Update batch 62 — First Steps

- Jalur 8 langkah pemain baru di kotak NEXT lobby (`DB.FIRST_STEPS`): Mailbox, Summon, Stage 1-1, hero Lv.5, hadiah Bond, Stage 1-3, pasang senjata, Chapter 1. Tiap langkah berhadiah; tombol GO berubah jadi CLAIM dan penunjuk mengarah ke sana.
- Progres dibaca dari save, jadi pemain lama cukup menekan CLAIM. Yang disimpan hanya langkah yang sudah diklaim (`s["first_steps"]`).
- Badge Heroes disembunyikan sampai menang pertama, supaya pemain baru tidak terdistraksi.
- Tes: flow_test blok `[first steps]` dan cek penarikan skin di `[special skins]`.

## 2bn. Update batch 63 — Jam pertama permainan

- Summon: tiket dipakai dulu, sisanya ditutup Gems (`Game.pull_pay`, bayar "mixed"). Hadiah mail selamat datang (5 tiket + 1.200 Gems) kini cukup untuk 10x pertama yang menjamin SSR; sebelumnya tidak bisa dicapai. Tulisan jaminan dipindah ke atas panel.
- Story: tab HARD disembunyikan sampai dibuka, tab ARC hanya menampilkan arc yang tercapai dan satu arc berikutnya.
- Battle pertama menampilkan satu baris penjelasan bahwa tim bertarung otomatis.
- Cek balance tim bawaan tanpa gear: Chapter 1 menang 85-100% di Lv.1 dan 100% di Lv.5, jadi tidak ada perubahan angka.

## 2bo. Update batch 64 — Scout Report

- Tombol BATTLE di Story sebelumnya berada di bawah area scroll; kini BATTLE, SWEEP, dan FORMATION dipasang tetap di bawah panel.
- `Game.scout(enemies)`: elemen utama musuh (boss berbobot 3x), elemen penangkalnya, dan hero milik pemain untuk elemen itu. Tampil di detail stage dan baris info Formation; hero penangkal diberi tanda "▲ +30%".
- Tombol AUTO di Formation yang punya musuh kini memperhitungkan keunggulan elemen (`auto_formation(prefer)`).
- `Game.defeat_tip(enemies)`: saran saat kalah kini spesifik (selisih power, atau nama hero penangkal), menggantikan tips umum.
- Formation: tombol di panel bawah lebih tinggi dari panelnya (186 vs 156 px), sehingga START BATTLE terpotong dan AUTO-REPEAT keluar layar. Kini tiga baris muat, dan REPEAT berada di samping START.

## 2bp. Update batch 65 — Ikon item yang bisa dibedakan

Hasil pemeriksaan layar Heroes, Hero Detail, Shop, Bag, Missions, Mail, Pass, Forge dan Settings. Tata letaknya aman, tapi banyak item memakai ikon yang sama sehingga mudah tertukar:
- Skin Ticket, Moonlight Perfume dan Celestial Gem sama-sama memakai `item_celestial_gem`, dan ikonnya mirip ikon Gems.
- Hero EXP Potion memakai ikon Hero EXP, Energy Flask dan Forge Ember memakai ikon Energy, Gold Pouch memakai ikon Gold.
- Sweet Cake sama dengan Bouquet; Universal Shard, Rune Pouch dan Hunt Core sama-sama `icon_shards`; Grand Rune Chest dan Royal Gear Chest sama-sama `icon_awakening`.

Perbaikan:
- `tools/gen_item_icons.py` menggambar 12 ikon baru dengan gaya yang sama (cakram gelap, cincin berwarna, simbol datar): `item_sweet_cake`, `item_perfume`, `item_skin_ticket`, `item_exp_potion`, `item_energy_potion`, `item_forge_ember`, `item_hunt_core`, `item_rune_pouch`, `item_star_stone`, `item_gold_bag`, `item_rune_chest`, `item_royal_chest`. Script bisa dijalankan ulang dari root proyek.
- `DB.ITEMS` diarahkan ke ikon baru. Header Hunter's Exchange (`hunt.gd`) dan tungku Salvage di Forge (`forge.gd`) ikut memakai ikon Hunt Core dan Forge Ember.
- flow_test `[item icons]`: setiap item harus punya file ikon, tidak boleh berbagi ikon dengan item lain, dan tidak boleh memakai ikon mata uang (Gold, Gems, Hero EXP, Energy).
- News `n2026-11-07g`.

Catatan kecil yang belum diubah: grid Bag hanya menampilkan ikon dan jumlah (nama baru muncul setelah item dipilih), dan Arena Coin tetap tampil walau x0.

## 2bq. Update batch 66 — Perbaikan layar Hero Detail & Wardrobe

Pemeriksaan tab Hero Detail (INFO, UPGRADE, GEAR, OUTFITS, BOND) dan Wardrobe, kali ini tanpa dialog tutorial yang menutupi layar (langkah baru `notips` di `tools/shot_runner.gd`).
- **Tab OUTFITS meluber:** sel grid punya lebar tetap 150 px dan tombol "UNLOCK 800 Gems" lebih lebar dari selnya, sehingga panel melebar keluar layar (kolom ketiga dan tab BOND terpotong). Sekarang sel berbagi lebar panel (`SIZE_EXPAND_FILL`), dan tombol dibuat dua baris: "UNLOCK / 320 Gems".
- **Tab BOND:** "GIVE A GIFT" dipindah tepat di bawah bar Bond. Sebelumnya ada di bawah Daily Talk dan Memories, jadi harus di-scroll, padahal langkah First Steps menyuruh pemain memberi hadiah.
- **Wardrobe:** teks "+10%% ATK & HP" (persen ganda, karena string tanpa format `%`) diperbaiki menjadi "+10%". "Recruit Ning" menjadi "Recruit Ning Er" (dulu nama dipotong di spasi pertama).
- **Pengaman:** `hero_detail` untuk hero yang belum dimiliki selalu membuka tab INFO, walau dipanggil dengan parameter `tab` lain (sebelumnya script error di tab OUTFITS).

## 2br. Update batch 67 — Messenger + nama item di Bag

**Messenger (fitur baru, buka di Player Lv.2):** hero mengirim pesan chat ke Commander.
- Setiap hari maksimal 3 chat baru masuk (`DB.MSG_PER_DAY`). Chat yang belum dibalas tetap ada dan mengisi kuota hari itu.
- Tiap hero punya 1 **chat pribadi** (33 hero, `DB.MSG_PERSONAL`), terbuka di Bond Lv.2 dan dikirim lebih dulu dari chat lain. Balasan pertama memberi +30 Gems.
- Selain itu ada 6 **chat harian** umum (`DB.MSG_TOPICS`) yang bergiliran per hero per hari.
- Pemain memilih 1 dari 2 balasan. Balasan favorit hero memberi +40 Bond, balasan lain +20 Bond. Keduanya menghitung misi "bond".
- Riwayat chat disimpan per hero (maks. 40 baris) di `s["messenger"]`.
- Layar baru `game/screens/messenger.gd`: daftar chat dengan wajah dan titik merah di kiri, gelembung chat di kanan, animasi "typing…" sebelum hero membalas.
- Tombol baru **Chats** di kolom kiri lobby (dengan badge jumlah pesan), entri di MENU → HEROES & BOND, dan tutorial singkat.
- Ikon baru `icon_messenger`, dibuat dengan `tools/gen_item_icons.py icon_messenger` (script sekarang bisa membuat ikon tertentu saja).
- `flow_test`: blok `[messenger]` (terkunci sebelum Lv.2, kuota harian, semua hero punya chat pribadi, format thread, Bond/Gems, tidak bisa balas dua kali, isi ulang hari berikutnya).

**Bag:** setiap kotak sekarang menampilkan nama item, nama set gear, jenis rune atau nama hero (untuk shard). Hero EXP, Energy dan Arena Coin disembunyikan kalau jumlahnya 0. Gold dan Gems selalu tampil.

## 2bs. Update batch 68 — Messenger: chat pribadi kedua & chat reaksi

- **Chat pribadi kedua** untuk ke-33 hero (`DB.MSG_PERSONAL2`). Terbuka di Bond Lv.6 setelah chat pribadi pertama dibalas, dan dikirim lebih dulu dari chat lain. Balasan pertama memberi +30 Gems.
- **Chat reaksi** (`DB.MSG_EVENTS`, 3 variasi masing-masing):
  - Setelah memberi hadiah (`give_gift`), hero yang menerima mengirim chat.
  - Setelah menang di story (`apply_stage_result`), satu hero acak dari formasi mengirim chat.
  - Masing-masing maksimal sekali sehari, dan tidak menambah pesan kalau sudah ada 5 chat yang menunggu.
  - Muncul pemberitahuan "New message from …" dan langsung masuk ke Messenger.
- Fungsi baru `Game.msg_notify(id, kind)`. Kunci thread: `p`, `p2`, `gift<N>`, `win<N>`, `t<N>`.
- `flow_test`: cek chat pribadi kedua, Gems, chat hadiah dan kemenangan beserta batas sekali sehari.

## 2bt. Update batch 69 — Tombol GO di Missions, misi Messenger, layar Arena, Redeem Code, 30 FPS

- Batch ini dimulai dengan memeriksa tampilan layar Arena, Guild, Summon, Tower, Daily Dungeon, World Boss dan Event lewat screenshot. Guild, Tower, Dungeon dan World Boss sudah rapi.
- **Arena:** panel kiri ditata ulang. Info musim dan hadiahnya, tiket, serta tombol ARENA SHOP dan FORMATION sekarang muat di layar tanpa scroll. Sebelumnya tombol terpotong dan info musim tersembunyi di bawah.
- **Bug Arena:** tombol ARENA SHOP dulu membuka tab Gem Shop. Sekarang membuka tab Arena Shop (`{"tab": "arena_coin"}`).
- **Tombol GO di Missions:** misi yang belum selesai sekarang punya tombol "GO ▶" yang membuka layar terkait, menggantikan tulisan "IN PROGRESS" yang tidak bisa ditekan. Tujuannya diatur di `DB.QUEST_ROUTE`, dan bisa dicari lewat id misi harian, `src` misi mingguan, atau `stat` achievement.
- **Misi Messenger:** misi harian baru "Reply to a hero's message" (+20 Gems, +3.000 Gold). Achievement baru: "Reply to 10 messages", "Reply to 50 messages" dan "Read 10 personal chats" (stat `chats` dan `personal_chats`).
- Nama achievement "Recruit every hero (27)" diganti menjadi "Recruit 27 heroes", karena sekarang ada 33 hero.
- `flow_test`: blok `[mission GO]` mengecek bahwa semua tujuan GO adalah layar yang ada dan semua misi punya rute. Ditambah cek penghitung balasan Messenger.

- **Frame rate (Settings → DISPLAY):** pilihan 60 FPS atau 30 FPS (hemat baterai). Disimpan di `settings.fps`, dipasang lewat `Game.apply_fps()` (`Engine.max_fps`) saat game dibuka.
- **Redeem Code (Settings → PLAYER):** kode di `DB.REDEEM_CODES` (`EUPHORIA2026`, `WELCOMECOMMANDER`, `HEROESTEXTME`). Huruf besar/kecil, spasi dan tanda "-" diabaikan, dan tiap kode hanya bisa dipakai sekali per save (`s["redeemed"]`). Karena repo publik, kode-kode ini bisa dilihat siapa saja. Untuk game offline hal ini tidak masalah.
- Fitur "Duo Links" sempat dikerjakan, tapi dibatalkan karena sistem **Links** (`DB.LINKS`, 22 pasangan) sudah ada.
- `tools/shot_runner.gd`: langkah baru `scroll:<px>`.

## 2bu. Update batch 70 — Kitchen (Dapur)

- **Layar baru Kitchen** (MENU → HEROES & BOND, terbuka di Player Lv.3, file `game/screens/kitchen.gd`). Panel kiri berisi level Kitchen, makanan yang sedang aktif, Market Basket, isi Pantry dan hidangan yang dimiliki. Panel kanan berisi daftar resep dengan tombol COOK dan COOK xN.
- **4 bahan** (`DB.INGREDIENTS`): Moonwheat Flour, Starberry, Dewleaf Herb, Wild Game. Sumbernya:
  - Menang di story, Hard dan Event: peluang 60% dapat 1 bahan. Boss selalu memberi 2 bahan.
  - Garden: tap hero kadang memberi Starberry atau Dewleaf Herb.
  - Expedition Herb Gathering: +3 Dewleaf Herb.
  - Market Basket gratis sekali sehari. Isinya 2 dari setiap bahan (8 total), cukup untuk langsung memasak di hari pertama. Setiap level Kitchen di atas Lv.1 menambah 1 bahan acak.
- **5 resep** (`DB.RECIPES`), masing-masing memakan bahan dan Gold:
  - Hadiah: Starberry Pancakes (+70 Bond) dan Starberry Tart (+110 Bond, butuh Kitchen Lv.2). Keduanya muncul di daftar GIVE A GIFT di Hero Detail dan Private Room. Hidangan ini tidak pernah jadi hadiah favorit hero, jadi favorit lama tidak berubah.
  - Meal: Hunter's Stew (ATK +8%, 3 battle), Dewleaf Salad (HP +12%, 3 battle), Royal Meat Pie (HP/ATK/DEF +7%, 5 battle, butuh Kitchen Lv.3).
- **Buff Meal:** tekan SERVE di Kitchen atau Bag. Buff berlaku untuk seluruh tim dan berkurang satu setiap kali battle sungguhan dimulai (`Game.meal_consume`, dipanggil dari tombol mulai di Formation dan dari Auto-Repeat). Sweep dan Arena tidak memakai Meal. Hanya satu Meal yang bisa aktif; Meal baru menggantikan yang lama.
- **Level Kitchen** naik sesuai total hidangan yang dimasak (`DB.KITCHEN_LV`: 0/10/30/60).
- Misi harian baru "Cook a dish in the Kitchen", dengan tombol GO ke Kitchen. Achievement baru "Cook 20 dishes" dan "Cook 60 dishes" (stat `dishes`). Badge di menu muncul saat Market Basket bisa diambil. Ada tutorial singkat dari Furu.
- Ikon baru: 4 bahan, 5 hidangan dan `icon_kitchen` (dari `tools/gen_item_icons.py`).
- `flow_test`: blok `[kitchen]` mengecek basket, resep, biaya, level, buff Meal di battle, pengecualian Arena dan drop bahan dari boss.

## 2bv. Update batch 71 — Poles tampilan (Missions, Bag, notifikasi, banner battle)

- **Missions** (`game/screens/quests.gd`): tiap baris kini punya ikon bulat di kiri sesuai layar tujuannya (`ROUTE_ICON`). Urutan baris: yang siap di-CLAIM paling atas, lalu yang masih berjalan, lalu yang sudah diklaim (redup 55%). Baris yang siap diklaim memakai panel bingkai emas dan ikon yang berdenyut. Layar Missions juga menerima parameter `tab` (dipakai oleh Bag untuk membuka COMMANDER ROAD).
- **Bag → OBTAIN FROM** (`DB.ITEM_SOURCES`, `DB.item_sources()`): detail item menampilkan sampai 4 sumber item, masing-masing dengan tombol GO. Sumber dari toko diambil otomatis dari `DB.SHOP` (Gem/Gold/Arena/Friend/Guild Shop). Layar yang masih terkunci menampilkan level buka, bukan tombol GO.
- **Notifikasi tergabung** (`main.toast`): notifikasi dengan awalan teks yang sama (misalnya beberapa "PLAYER LEVEL UP! Lv.x" berturut-turut) diganti dengan yang terbaru, jadi tidak lagi menumpuk menutupi lobby. Notifikasi "NEW FEATURE UNLOCKED: X!" digabung menjadi satu daftar.
- **Banner awal battle** (`battle.gd _intro_banners`) dibuat lebih ramping (font 14, padding 6) dan diturunkan ke bawah strip potret, jadi tidak menutupi hero di baris depan.
- Berita baru n2026-11-08c "Quality of Life: Missions & Bag".

## 2bw. Update batch 72 — Tampilan baru Tower of Trials & tangga rank Arena

- **Tower of Trials (`game/screens/tower.gd`) didesain ulang:**
  - Kolom kiri "THE CLIMB" berbentuk jalur vertikal. Garis emas menyala dari lantai yang sudah dilewati sampai lantai sekarang, dan lantai yang sudah selesai diberi tanda centang.
  - Lantai Guardian (tiap 5 lantai) ditandai merah, lengkap dengan hadiah gem dan Summon Ticket.
  - Lantai sekarang berdenyut, dan daftar otomatis menggulir ke lantai tersebut.
  - Bagian atas menampilkan "Best: Floor N" dan "Guardian in N".
  - Panel kanan punya banner medan pertempuran lantai itu (galaxy/hell/ice/asgard) dan meter THREAT (FAVORED / EVEN FIGHT / RISKY / DEADLY) yang membandingkan power tim dengan musuh.
  - Kartu musuh sekarang menampilkan nama dan label BOSS.
  - Kotak FIRST CLEAR juga menampilkan hadiah Guardian berikutnya. Ada tombol TEAM di samping CHALLENGE.
- **Arena (`game/screens/arena.gd`):**
  - Panel kiri sekarang punya "SEASON TIERS": bar progres menuju tier berikutnya, dan keenam tier lengkap dengan batas RP serta hadiah gem dan tiket. Tier sekarang berdenyut, dan tooltip-nya menampilkan hadiah lengkap.
  - Teks yang dobel diringkas: hadiah tier sekarang dan catatan "Practice season" dipindah ke tooltip.
- **Tools:** `shot_runner.gd` punya step baru `gset:path.key|nilai` untuk mengubah state save saat mengambil screenshot (mis. `gset:tower.floor|10`).

## 2bx. Update batch 73 — Tampilan baru Kitchen

- **Kartu level dapur**: cincin progres berisi "Lv N", gelar koki (Apprentice → Home Cook → Chef → Master Chef), jumlah masakan "14 / 30 dishes", dan isi buka di level berikutnya (resep baru + basket lebih besar).
- **TODAY'S MEAL**: label ACTIVE, ikon makanan bernapas, dan bulatan (pip) untuk sisa pertempuran buff.
- **Pantry**: ubin bahan bisa diklik — langsung ke tempat bahan itu jatuh (Story, Garden, Expedition) memakai `DB.item_sources`; tooltip berisi semua sumber; bahan habis diberi bingkai merah.
- **Dishes on hand**: kartu kecil berwarna (oranye = MEAL, pink = GIFT) dengan tombol SERVE/GIFT.
- **Kartu resep**: garis warna jenis, piring bercahaya di belakang ikon, tag MEAL/GIFT berbentuk pil + durasi buff, chip bahan "punya/butuh" (hijau ✓ / merah kurang), bingkai hijau berdenyut + "READY xN" jika bisa dimasak, overlay LOCKED + "N more dishes" untuk resep terkunci.
- **Filter ALL / MEALS / GIFTS** dan penghitung "N ready to cook" di judul.
- **Efek masak**: kartu yang baru dimasak "pop" dan angka "+N" melayang dari ikon.

## 2by. Update batch 74 — Tampilan baru Expedition

- **Strip ringkasan** di atas: ACTIVE n/5, READY, HEROES OUT, info Bond, dan tombol **CLAIM ALL** (klaim semua ekspedisi yang selesai sekaligus, hadiah digabung dalam satu popup).
- **Kartu misi**: banner pemandangan per misi (forest, outland, asgard, dragonfire, blackhole) dengan chip durasi dan status (AVAILABLE / IN PROGRESS / COMPLETE / LOCKED).
- **Slot hero**: lingkaran "+" kosong sesuai jumlah hero yang dibutuhkan; terisi wajah hero saat berjalan. Label "+10 Bond each".
- Syarat "Hero Lv.N+" berwarna merah dan tombol SEND nonaktif (dengan tooltip) jika belum ada hero yang memenuhi; banner digelapkan.
- Saat berjalan: bar progres + timer + hadiah dalam satu baris; selesai: bingkai hijau dan "Ready to claim!".

## 2bz. Update batch 75 — Lobi Guild baru

- Layar "belum masuk guild" sekarang dua kolom.
- **Kiri — WHY JOIN A GUILD?**: 3 kartu manfaat (Guild Raid, Guild Coins, Team Power +1% ATK & HP per level), catatan guild offline, dan kotak **FOUND YOUR OWN** (nama + CREATE 300 Gems; nonaktif jika gem kurang).
- **Kanan — RECOMMENDED GUILDS**: kartu per guild dengan lambang perisai berwarna (huruf awal), badge level, tag gaya main (RAID/ACTIVE, CASUAL/BOND, TOWER/ARENA), anggota "28 / 30", bonus "+5% ATK & HP" (sesuai `guild_bonus` = level − 1), dan bar ACTIVITY.
- `DB.GUILDS` mendapat field baru: `color`, `tags`, `members`, `activity` (opsional, ada default).

## 2ca. Update batch 76 — Panel kiri Guild Hall

- Lambang perisai guild (warna sesuai `DB.GUILDS`, emas untuk guild buatan sendiri) + nama + level.
- Bar EXP dengan pratinjau "next: +N%", kotak hijau "Guild buff: +N% ATK & HP".
- **TODAY checklist** (`_task`): Check-in (CLAIM), Donate n/3 (GIVE), Raid n/3 left — baris yang selesai diberi ✔ hijau, tombol aksi berdenyut.
- Berita "New Look: Guild" digabung dengan update lobi (batch 75).

## 2cb. Update batch 77 — Daily Dungeon

- Pilihan dungeon (kiri) jadi banner pemandangan (`bg` tiap dungeon) dengan gradasi gelap, ikon, nama, jenis hadiah (Gold / Hero EXP & Potions / Gear & Chests), pip percobaan hijau, dan "Best Lv.N" / "Not cleared". Yang dipilih berbingkai emas.
- Tiap level (kanan) punya medali angka (✔ hijau jika sudah clear), wajah musuh (gelap jika terkunci, tooltip nama), "Enemy Lv / Power", dan tag ancaman FAVORED / EVEN / RISKY / DEADLY (perbandingan `team_power` vs `enemy_power`, tooltip angka).

## 2cc. Update batch 78 — Forge saat kosong

- Belum punya gear: kartu **YOUR ARMORY IS EMPTY** + daftar "WHERE TO GET GEAR" (Armory Ruins, Gear Chests di Bag, ekspedisi Ancient Ruins, boss Story) dengan tombol GO (atau "Lv.N" jika fitur terkunci).
- Tengah: ikon perlengkapan transparan "THE ANVIL AWAITS".
- Kanan (`_right_help`): penjelasan tab REFORGE / TEMPER / FUSE + biaya + catatan bahwa Forge Embers didapat dari SALVAGE.

## 2cd. Update batch 79 — Bestiary

- Header "DISCOVERED n / 15" dengan bar progres emas.
- Entri musuh yang belum ditemui (`_unknown_detail`): petunjuk kelas (TANK/RANGER/…), "WHERE TO FIND HER" (dungeon yang memuat musuh itu + Story, dengan GO), daftar **HUNTING REWARDS** per tier kill, dan info taming setelah 20 kill.

## 2ce. Update batch 80 — Season Pass

- Header: cincin level PASS (progres EXP), chip "Ends in N days", "• N rewards ready", bar EXP, dan sumber Pass EXP sebagai chip. Tombol UNLOCK PREMIUM berdenyut; jika aktif → kotak hijau "PREMIUM ACTIVE ✔".
- Lajur hadiah: kolom per level = sel FREE, **node level** di garis tengah (garis emas menyala sampai level kamu, lingkaran bernomor, berlian untuk tiap level ke-5), sel PREMIUM.
- Sel milestone (tiap 5 level) berbingkai emas tebal + ★; sel siap klaim berbingkai hijau berdenyut; premium yang belum dibeli redup + LOCKED; tooltip berisi isi hadiah.
- Panel **GRAND PRIZE** Lv.30 di kanan (Oath Ring + 5 Summon Ticket, ikon bernapas, "N levels to go", tombol VIEW menggulir ke akhir lajur).
- Saat dibuka, lajur langsung menggulir ke hadiah pertama yang belum diklaim.

## 2cf. Update batch 81 — Gallery

- Strip atas: "COLLECTION N% • x / 33 heroes met" + bar emas, tombol filter ALL / OWNED / LOCKED (`_build_list` membangun ulang daftar).
- Judul tier menampilkan jumlah hero yang dimiliki ("1 / 14"); hero yang dimiliki diurutkan di depan.
- Kartu terkunci: siluet gelap + tanda "?" besar berwarna rarity + tooltip "Summon this hero…"; kartu dimiliki: gradasi bawah, badge COMPLETE jika semua outfit terbuka.
- Penyesuaian kolom grid lewat satu handler `_fit_cols` (aman saat filter membangun ulang grid).

## 2cg. Update batch 82 — Messenger gaya aplikasi chat

- Avatar bulat (`_avatar`) dengan titik hijau "online"; daftar chat memakai pil merah **NEW** untuk pesan baru dan kartu tips Perfect Reply di bawah.
- Bar judul chat: avatar, nama, "● Online", badge "♥ Bond Lv.N".
- Gelembung (`_bubble`) menyesuaikan lebar teks (bungkus hanya jika > ~62% lebar chat), sudut "ekor" di sisi pengirim, cap waktu malam (21:06…), centang ✓✓ untuk balasan kamu, dan indikator mengetik "• • •" yang berkedip.

## 2ch. Update batch 83 — Hadiah Private Room

- Tombol teks hadiah diganti grid 3 kolom ubin ikon (`_gift_tile`): ikon item, jumlah, ♥ + bingkai pink untuk hadiah favorit (Bond x2), redup jika 0, tooltip nama + deskripsi.

## 2ci. Update batch 84 — Starlight Rift

- **Peta lantai** (`_rift_map`): 10 lantai berikutnya di satu garis; lantai Guardian (tiap 5) berupa berlian merah, lantai sekarang bercahaya emas, garis ungu menyala untuk lantai yang sudah dilewati, label "BEST".
- **Kartu NEXT GUARDIAN** (`_guardian_card`): wajah hero varian, "Ashen/Hollow/Mirror… Nama", Lv, jumlah musuh, power (dari `DB.rift_floor`).
- Info "Resets in Nd" di samping best floor.
- **Floor Rewards**: medali berlian bernomor, bar progres (best / target) untuk yang belum tercapai, tombol CLAIM emas berdenyut saat siap, label CLAIMED saat sudah diambil (menggantikan tombol CLAIM nonaktif).

## 2cj. Update batch 85 — World Boss

- **Hadiah damage** jadi tier I–V: medali heksagon (hijau = siap, oranye = target berikutnya + pil **NEXT**, ungu = terkunci, ✓ = sudah diambil), bar progres per tier, persen, CLAIM emas berdenyut, label CLAIMED.
- Strip ringkasan di atas: "N more damage to Tier X", "a / b tiers claimed • n ready", dan trek tier tersegmentasi (`_tier_track`).
- Panel kiri: chip statistik (WEEKLY DMG / BEST HIT / RANK) dan pip jatah serangan harian.
- **Ranking**: podium Top-3 (`UI.podium`, mahkota ♛ untuk #1) dan kotak "You are #N — this week's reward: …".
- **Bug fix**: tab RANKING di World Boss & Rift sebelumnya selalu kembali ke tab pertama (`_tab` hilang saat `main.replace`). Sekarang tab dikirim lewat `params.tab`.

## 2ck. Update batch 86 — Friends

- Layout dua panel. Kiri: kartu profil (avatar bulat, Lv, ID), chip FRIENDS / SUPPORTS / POINTS, kotak **DAILY HEARTS** (hati berdenyut, tombol SEND TO ALL), dan "HOW FRIENDS HELP" (3 langkah berikon).
- Kanan: filter ALL / AVAILABLE / USED TODAY, grid 2 kolom kartu teman (status online / "5m ago", ♥ jika hati sudah dikirim, pil SUPPORT READY / HELPED TODAY, kartu yang sudah dipakai diredupkan dan diletakkan di akhir).

## 2cl. Update batch 87 — Shop & Black Market

- Kartu pertama tiap tab adalah kartu info: saldo, deskripsi, "⟳ Restocks in Xh Ym", dan pintasan (EARN POINTS / GO TO ARENA).
- Kartu item: ikon di atas lingkaran cahaya, tag FREE / POPULAR / LIMITED, bar stok, tombol harga dengan ikon mata uang (teks merah + tooltip jika tidak cukup), cap "SOLD OUT" miring, tombol FREE berdenyut.
- Black Market: kartu refresh di depan, tag diskon, "was N" (harga asli), potret bulat untuk shard hero (sebelumnya terpotong), ukuran kartu seragam.

## 2cm. Update batch 88 — Boss Hunt

- Pemilih kesulitan diganti ubin berwarna (`_diff_tile`): NORMAL hijau, HARD biru, NIGHTMARE ungu, ABYSS merah; berisi Lv, ✓ jika sudah clear, LOCKED + tooltip "Clear X first".
- Perbandingan power (`_power_compare`): bar YOU vs FOE dan tag FAVORED / EVEN / RISKY / DEADLY.
- Pip jatah berburu harian; tombol HUNT berdenyut.
- Daftar target: pip berlian 4 kesulitan (terisi = sudah clear) dan nama kesulitan terbaik.
- Hunter's Exchange: tombol dengan ikon Hunt Core (merah jika tidak cukup), bar stok, "a / b left this week".

## 2cn. Update batch 89 — Date (empty state) & Festival Exchange

- Date tanpa partner: panel "NO DATE PARTNER YET" dengan hati berdenyut, 4 hero terdekat ke Bond Lv.3 (bar progres + tombol GIFT ke tab BOND), dan 4 ubin "WAYS TO RAISE BOND" (Gifts, Daily Talks, Private Room, Kitchen).
- Spot kencan terkunci menampilkan 🔒 dan progres "x / y stages".
- Festival: chip Lantern Charms dengan bar batas harian; Exchange memakai ikon charm, bar stok, harga merah jika tidak cukup, dan baris redup saat habis.

## 2co. Update batch 90 — Mailbox gaya inbox

- Dua panel. Kiri: daftar surat dengan ikon pengirim, tag (EVENT / UPDATE / GIFT), pengirim, tanggal, titik merah belum dibaca, "🎁 N", dan ✓ jika sudah diklaim (`META` per id surat).
- Kanan: surat bergaya kertas krem (tag, judul, "From:", garis emas, "Dear Commander,", isi surat, kotak ATTACHMENTS, tombol CLAIM REWARDS berdenyut). Setelah klaim, surat belum diklaim berikutnya terbuka otomatis.
- Tombol header menjadi "CLAIM ALL (n)" atau "ALL CLAIMED".
- Catatan teknis: `UI.fade_in` jangan dipakai pada anak Container karena menimpa posisi hasil layout (padding hilang). Gunakan tween `modulate:a` saja.

## 2cp. Update batch 91 — Photo Studio

- Kartu hero (wajah, nama, outfit, tombol CHANGE) menggantikan teks info.
- Stepper menampilkan judul kecil dan nilai saat ini, misalnya "Outfit 1 (1/11)", "Lobby (1/25)", "Warm (2/8)", "Gold (2/5)".

## 2cq. Update batch 92 — Garden

- Kartu "RESIDENTS TODAY" di kiri atas: wajah, nama, Bond, dan ♥♥♡♡♡ tap harian; jumlah total "N taps left"; diperbarui setiap tap.
- Hint diubah jadi pil gelap; area jalan chibi digeser ke kanan supaya tidak tertutup kartu.

## 2cr. Update batch 93 — Summon

- Rate jadi 3 chip berwarna (SSR / SR / R).
- PITY dan SPARK digabung dalam satu kartu meter (`_meter`): bar berwarna dengan angka; tombol EXCHANGE berdenyut saat spark penuh.
- Tombol summon berikon tiket atau permata (teks merah jika tidak cukup); FREE DAILY berdenyut.

## 2cs. Update batch 94 — Wardrobe

- Header koleksi "a / b owned" dengan bar.
- Chip bonus (+10% ATK, +10% HP, LIVE ART) dan "OUTFIT LINE-UP" (semua outfit hero, yang spesial berbingkai emas, yang terkunci diredupkan).
- Jika hero belum dimiliki: kotak merah dengan tombol "FIND HER IN SUMMON".
- Tombol tiket skin dan harga permata berikon (harga merah jika tidak cukup).

## 2ct. Update 8 Nov — 4 hero baru + enemy Octra + Arc 10

- Import aset (background sudah dihapus manual) lewat `tools/import_nov8.py`. Skrip ini memakai helper `import_nov4.py`, dengan tambahan: file huruf yang tidak punya base (`queengumi_char_evo1a`) dijadikan base; `evo3aa` dihitung sebagai ekspresi alternatif; file `banner` dan `special` dipisah.
- Hero:
  - **Gala** (SR, FIRE MAGE, Nebula Parasol)
  - **Morana** (SSR, DARK HEALER, Black Mass Benediction, skin spesial "Moonlit Vigil Veil")
  - **Seraph** (SSR, LIGHT MAGE, Thousand-Eye Judgement)
  - **Tamo** (SSR, EARTH WARRIOR, Nine-Tail Greatsword, skin spesial "White Fox Bride")
- Enemy: **Octra** (DARK MAGE, Abyss Beast Maw). Bisa dijinakkan (PET_LINES), masuk RIFT_POOL, dan bannernya ada di `art/banners_event/banner_octra_1.png`.
- Data per hero:
  - stats dan skill, greet VOICE, profil, voice_lines (JP+EN, sudah digenerate ke `audio/voice`), 3 memori;
  - MSG_PERSONAL dan MSG_PERSONAL2, 2 Story Link (Halo & Veil, Foxfire & Lava);
  - 3 banner rate-up, mail "heroes_nov8", depth map 2.5D.
- Arc 10 "The Abyss Choir":
  - Chapter 39 "Choir of the Abyss" (boss hollow Octra) dan Chapter 40 "Queen of Foxfire" (boss ashen Tamo). Total jadi 40 chapter / 240 stage.
  - Interlude i10 "Midnight Choir Practice".
- Flow test diperbarui: 37 hero, 40 chapter, cek aset hero/enemy baru.

## 2cu. Fitur viewer karakter layar penuh

- `game/ui/art_viewer.gd` (class `ArtViewer`) adalah overlay layar penuh untuk hero dan enemy. Latarnya peta elemen yang digelapkan, ditambah glow warna tema dan partikel.
- Kontrol:
  - pinch, scroll, atau pinch trackpad untuk zoom (1x–4x) di sekitar jari; drag untuk geser (pan dibatasi tepi); double-tap untuk close-up 2.4x;
  - tap untuk interaksi: kata-kata dengan voice, ekspresi alternatif acak, animasi per bagian tubuh, hati; usap kepala untuk pat (bond hero / pat pet).
- Tombol:
  - ◀ ▶ untuk outfit atau form yang sudah terbuka, plus titik indikator;
  - ☺ untuk ganti ekspresi secara permanen saat melihat (`DB.alt_arts`);
  - ⟲ reset zoom, ◐ sembunyikan UI, ✕ tutup (BACK/ESC juga menutup).
- Tombol kaca pembesar (`UI.zoom_button`, ikon `art/icons/icon_zoom.png`) dipasang di Hero Detail (pojok kanan atas art) dan Bestiary (pojok kanan atas art; enemy harus sudah pernah dikalahkan).
- `tools/shot_runner.gd` mendapat langkah `viewer:id|outfit|zoom` dan `detail:screen|id`.

## 2cv. Update batch 95 — Bag

- Tab menampilkan jumlah isinya (ITEMS 5, GEAR 9, …). Tab Items punya filter ALL / CURRENCY / UPGRADE / CHESTS / GIFTS / FOOD.
- Tile berbingkai warna sesuai jenis atau rarity, dengan glow di belakang ikon, pil jumlah atau tier, dan badge E (dipakai), ! berdenyut (bisa dipakai atau dibuka), L (gear terkunci). Shard hero tampil sebagai wajah bulat dengan bar menuju Star Up atau recruit.
- Ringkasan di bawah grid ("9 pieces • 0 equipped").
- Tab kosong menampilkan kartu panduan (ikon, judul, sumber, tombol GO). Panel kanan menampilkan petunjuk "Pick something…".
- Panel detail item punya medali ikon dengan glow berdenyut, nama, tag grup, dan jumlah yang dimiliki.

## 2cw. Ekspor ikon untuk diedit manual

- `tools/export_icons.py` menyalin semua ikon dan aset UI (art/icons, art/ui, art/vfx, art/brand tanpa backup) ke `Karakter Euphoria Online/icon asset/`. Aset dibagi ke folder buatan artist: Symbol in game, Icon all item in backpack, Icon shop, Weapon, ditambah UI frame & button, VFX, Logo & brand.
- Hasilnya juga mencakup lembar katalog `SHEET_*.png` dan `ALL_ICONS.png` (ikon dengan nama in-game, nama file, dan ukuran), `icon_manifest.json`, serta README berisi aturan edit dan contoh Gemini CLI.
- `tools/import_icons.py` (dry run) dan `--apply` menyalin kembali ikon yang berubah ke game. Ukuran otomatis disesuaikan ke ukuran asli, salinan yang terakhir diedit yang dipakai, dan file lama di-backup ke `_recut_backup/icons_*`.

## 2cx. Update batch 96 — Settings

- Dua kolom. Kiri: kartu profil Commander (wajah partner, nama, level, ID, bar EXP, chip HEROES / STAGES / TEAM POWER / PARTNER, rename) dan kartu SAVE DATA (peringatan, backup, restore, replay intro, title screen, tombol reset merah). Kanan: kartu AUDIO, BATTLE & GRAPHICS, DISPLAY, REDEEM CODE.
- Slider audio menampilkan persen dan punya tombol MUTE/ON; ada tombol tes suara partner.
- Toggle berupa baris dengan judul, penjelasan, dan status ON/OFF. UI size dan frame rate berupa tombol segmen.

## 2cy. Update batch 97 — Heart Catch

- Layar mulai minigame bukan popup lagi. Kiri: art hero besar (bergerak hidup) dengan glow pink, hati melayang, dan plat nama (elemen, nama, Bond). Kanan: kartu berisi judul, sisa reward play sebagai 3 ikon hati, 3 kotak item (Heart +1, Gold Star +5, Bomb -3 & stun), penjelasan combo, jalur hadiah (skor berapa pun → Gold, 40+ → Flower Bouquet, 70+ → 30 Gems) yang menyala sesuai skor terbaik, dan info Bond EXP.
- Pilih hero langsung dari deretan wajah di kartu (diurutkan dari Bond tertinggi), tanpa popup.
- Kalau reward play habis, tombolnya jadi PLAY FOR FUN dengan keterangan.
- Popup hasil: skor besar, lencana NEW BEST, sisa poin ke hadiah berikutnya, dan tombol MENU untuk kembali ke layar mulai (ganti dari EXIT).

## 2cz. Update batch 98 — Formation: Team Check

- Panel "Tactics Guide" yang dulu berupa tembok teks diganti TEAM CHECK yang membaca tim saat ini dan ikut berubah setiap kali tim diubah: tim penuh (x/5), Tank di kolom depan, Healer/support, 3 baris terisi, dan sinergi elemen (beserta "1 hero lagi → +x%").
- Cek yang gagal muncul paling atas (ikon ! oranye) dengan saran perbaikan; ada nilai keseluruhan NEEDS WORK / DECENT / STRONG / PERFECT.
- Roda elemen ditampilkan sebagai ikon (Fire › Wind › Earth › Water › Fire, Light ⇄ Dark).
- Tombol ALL TIPS membuka popup Tactics Guide lengkap (10 tips bernomor).

## 2da. Update batch 99 — Event Starfall Christmas + skin Hyeonxa "Scarlet Mistletoe"

- Aset dari `Special Event/Hyeonxa Skin Christmash` diimpor dengan `tools/import_xmas.py`: outfit spesial (`hyeonxa_char_special.png`), ekspresi alternatif (hydra merah), sprite battle chibi (`hyeonxa_sprite_special.png`) dan banner (`art/banners_event/banner_hyeonxa_xmas_1.png`, dipakai sebagai art di layar Event).
- Event baru "Starfall Christmas" (bg ice, efek salju, warna merah): 5 stage (Snowbell Lane → The Grinch Hydra, boss Octra), prolog dan epilog Hyeonxa + Valeria, exchange: **Skin Scarlet Mistletoe 1.800 token (limit 1)**, Hyeonxa Shard, Summon Ticket, Royal Gear Chest, Sweet Cake, Gems, Universal Shard.
- Event ini **dipin di kalender**: aktif 8 Nov 2026 – 1 Jan 2027 (`DB.EVENT_PINS`, pakai day_key WIB). Selama itu rotasi 14 hari ditahan; setelahnya rotasi 5 event lama jalan lagi (event berskin tidak ikut rotasi). Progress event tidak di-reset tiap 14 hari selama pin.
- Skin ini **eksklusif event** (`DB.EVENT_SKINS`): tidak bisa dibeli di Wardrobe (ditampilkan kartu "EVENT EXCLUSIVE" + tombol GO TO EVENT), label kunci di Hero Detail "EVENT • STARFALL CHRISTMAS" dengan tombol EVENT ▶.
- Hadiah baru `skin:<hero>` di sistem reward (nama, ikon wajah skin). Bisa diklaim sebelum hero direkrut; baru bisa dipakai setelah hero dimiliki.
- Sprite battle mengikuti skin: `DB.sprite(id, star, skin)` memakai `special_sprite` kalau skin spesial dipakai (battle, formation, garden, Heart Catch).
- Hyeonxa dikeluarkan dari daftar skin yang ditarik (`WITHDRAWN_SKINS`).
- Mail "Starfall Christmas" dengan 200 Event Token.
- **Layar Event baru**: kartu judul (tag LIMITED EVENT, timer, progres stage dan bintang), art dengan glow warna event, kartu "LIMITED SKIN" di kiri bawah (bar token menuju 1.800, tombol CLAIM / WEAR NOW / status OWNED), tab STAGES (kartu bernomor, tag BOSS), EXCHANGE (skin disorot paling atas, harga merah kalau token kurang) dan STORY (putar ulang prolog; epilog terbuka setelah boss dikalahkan). Setelah klaim skin langsung dipakai dan viewer layar penuh terbuka.

## 2db. Update batch 100 — Missions

- Dua kolom. Kiri: 4 kartu tab (Daily, Weekly, Achievements, Commander Road) dengan ikon, bar progres (selesai/total) dan pil emas berdenyut berisi jumlah hadiah siap diklaim.
- Di bawahnya kartu ringkasan tab aktif: penjelasan, hitung mundur reset (harian 00:00 UTC+7 / mingguan), total hadiah yang siap diklaim, tombol CLAIM ALL (abu-abu kalau tidak ada yang bisa diklaim).
- Kanan: daftar misi dikelompokkan dengan judul bagian READY TO CLAIM / IN PROGRESS / COMPLETED beserta jumlahnya.

## 2dc. Update batch 101 — Ikon semi-3D (Gemini) & Hero Codex

- **Ikon baru dari sheet Gemini** (`Karakter Euphoria Online/icon asset/semi_3d_icons_v2/ALL_ICONS_BETA.png`):
  - `tools/import_icon_sheet.py` memotong tiap sel sheet (layout 12 kolom sama dengan `ALL_ICONS.png`) dan menghapus background gelap. Hasil potongan disimpan di `semi_3d_icons_v2/<folder>/<file>.png`.
  - Setelah itu ikon diperkecil ke ukuran aslinya di game. File lama di-backup ke `_recut_backup/icons_semi3d_<waktu>/`.
  - File PNG yang ditaruh manual di `semi_3d_icons_v2/<folder>/` menang atas sel sheet. Saat ini itu `icon_gold.png` dan `item_oath_ring.png`.
  - Total **64 ikon** diganti: 62 dari sheet + 2 file manual.
  - 19 sel **dilewati** (daftar `SKIP` di script) karena Gemini menggambar benda lain:
    - Bag jadi lambang, Date jadi portal, Friends jadi lambang bersayap;
    - Gear Chest jadi koin perak, Gems jadi koin emas, Event jadi kristal, Hero Shards jadi permata;
    - Hunter's Stew jadi buah, Starberry Tart jadi ramuan, Hero EXP Potion jadi arang, Forge Ember jadi koin;
    - Starberry, Moonwheat Flour, Dewleaf Herb dan Wild Game jadi kristal/buku/bijih;
    - Royal Gear Chest dan Grand Rune Chest jadi lambang.
  - Sel UI frame/tombol 9-slice dan logo **tidak** diambil dari sheet, karena bentuknya berubah (tombol jadi permata segi delapan) dan akan merusak tombol di game.
  - Cara pakai ulang: `python3 tools/import_icon_sheet.py` (cek dulu), lalu `--apply`, lalu `Godot --headless --import`.
- **Hero Codex** (popup dari layar Heroes):
  - Kartu progres total (x / 148) dan 4 kartu tahap (Recruited, 5★, Bond 10, A5), masing-masing dengan ikon hadiah dan jumlah yang sudah diklaim.
  - Hero yang punya hadiah siap klaim tampil paling atas, lalu hero yang dimiliki, lalu yang belum.
  - Tiap tahap berupa chip:
    - sudah diklaim → hijau ✓;
    - siap → emas berdenyut "CLAIM ▸", bisa diklaim satu per satu (`Game.claim_codex(id, step)` baru);
    - belum → bar progres + teks (mis. `3 / 5★`, `Bond 1 / 10`, `A0 / A5`).
  - Footer: total hadiah siap klaim + CLAIM ALL.
- Tes: flow test baru untuk klaim satuan dan penolakan tahap yang sudah diklaim / belum tercapai.

## 2dd. Update batch 102 — Perbaikan unduhan web di HP & Arena baru

**Bug: unduhan gagal saat pindah tab di HP.** Browser HP memutus unduhan saat tab ditinggal. Loader bawaan Godot hanya mencoba ulang 4× dengan jeda 1 detik dan selalu mulai dari 0, jadi semua percobaan habis selagi tab masih di belakang. Setelah itu tidak ada tombol untuk mencoba lagi.
- Loader baru `tools/web_loader.js` (disisipkan ke `web/index.html` oleh `tools/publish_web.sh`) mengunduh `.pck` (3 part) dan `.wasm` dengan **resume**. Kalau koneksi putus, macet 20 detik, atau isi file terpotong, loader menunggu tab aktif lagi lalu melanjutkan dari byte terakhir dengan HTTP Range. Percobaan ulang memakai `cache: no-store`, jadi salinan rusak di cache browser tidak bisa memblokir.
- Layar loading menampilkan "Unduhan dijeda" / "menyambung ulang", dan layar error punya tombol **↻ Coba Lagi**.
- Diuji dengan server lokal yang memutus koneksi di tengah file, mengabaikan Range, dan macet. Hasil `.pck` dan `.wasm` identik byte-per-byte (MD5).

**Arena:**
- Kartu lawan menampilkan potret hero terkuat, chip tier berwarna, power lawan vs power kamu (bar), wajah tim dengan ikon elemen, label **EASY / EVEN / HARD**, hadiah menang (+24 RP, 60 Arena Coin, 3K Gold), dan tombol BATTLE.
- Footer "YOUR TEAM": formasi, power, tiket hari ini, dan tombol FORMATION (tombol FORMATION di panel kiri dihapus).
- Tab Ranking: podium Top 3 dan chip tier di setiap baris.

## 2de. Update batch 103 — Private Room: Bond Journey

- Kartu **Bond Journey** di panel kanan Private Room: wajah hero (bulat), Bond Lv + angka EXP (mis. `70 / 220`), bar pink, dan **10 hati** (♥ = sudah tercapai, ♡ emas = level yang membuka sesuatu). Arahkan kursor ke hati untuk melihat isi hadiahnya.
- Baris **NEXT** menunjukkan milestone terdekat (ruangan baru, Memory story, Date, outfit, Oath). Di Bond 10 berubah jadi "Max Bond — Oath Ceremony in Hero Details".
- Tombol TALK dan REST menampilkan bond yang didapat (+15/+30, x2 di ruangan favorit). Angka bond disembunyikan saat sudah MAX.
- Setelah Talk/Rest, angka "+N ♥" dan hati-hati kecil melayang dari hero.
- Daftar hadiah per level dipindah ke `DB.bond_unlocks()`, dipakai bersama oleh layar Bond Up (`main.gd`) dan Private Room. Layar Bond Up sekarang juga menyebut ruangan baru dan Date.

## 2df. Update batch 104 — Kartu hero baru & 11 ikon semi-3D

**Kartu hero (`game/ui/hero_card.gd`, dipakai di Heroes, Formation, Room, Summon, dll.):**
- Latar warna polos diganti cahaya radial berwarna elemen di belakang hero (tekstur gradien dibuat sekali lalu dipakai bersama semua kartu).
- Rarity jadi chip berbingkai, ada garis aksen warna rarity di atas nama.
- Hero yang belum dimiliki: ikon gembok, atau bar progres shard (`40 / 80`). Kalau shard sudah cukup, muncul label emas **✦ RECRUIT!**.

**Ikon baru dari `semi_3d_icons_v2`:** Gems, Celestial Gem, Crystal (Hero EXP), Energy, Ticket, elemen Fire/Water/Wind, dan gear Armor/Weapon/Helmet. Semuanya diimpor dengan `tools/import_icon_sheet.py --apply`, ikon lama di-backup di `_recut_backup/`.
- **Perbaikan importer:** sebelumnya file yang kamu taruh setelah sheet dibuat akan ditimpa potongan sheet lama saat `--apply`. Sekarang file yang sudah ada di folder tidak pernah ditimpa (pakai `--recut` untuk memotong ulang sheet). Cukup ganti PNG di folder lalu jalankan ulang.
- Elemen Earth/Light/Dark dan gear Boots/Gloves/Relic masih memakai ikon versi Batch 101.


## 2dg. Update batch 105 — Tower of Trials: Milestone Chests
- `DB.TOWER_MILESTONES` (8 peti): F10 200 gem + 1 tiket, F20 300 gem + Gear Chest + 50K gold, F30 2 tiket + Rune Chest, F40 500 gem + 2 Celestial Gem, F50 3 tiket + 2 Gear Chest, F60 800 gem + 2 Rune Chest, F80 5 tiket + Special Skin Ticket, F100 1.500 gem + Oath Ring.
- Save: `s.tower.claimed` (indeks, dinormalisasi ke int di `_sanitize`). Peti "ready" bila lantai itu sudah dilewati (`tower.floor > floor`), jadi pemain lama langsung bisa klaim milestone yang sudah terlewati.
- `Game.tower_milestone_state / tower_milestones_ready / claim_tower_milestone`; `feature_badge("tower")` menghitung peti siap klaim.
- `tower.gd`: teks penjelasan diganti panel **MILESTONE CHESTS** — jalur 5 medali (mulai dari peti pertama yang belum diklaim) dengan bar progres antar-medali; medali siap klaim berdenyut + chip hijau "CLAIM Fxx" (ketuk untuk klaim). Penjelasan aturan dipindah ke tooltip tombol TEAM. Banner lantai 112→100 px agar semua muat di 720p.
- Kartu musuh: 84×100, ikon elemen + level; kartu Guardian berdenyut merah.
- flow_test: blok `[tower milestones]`.


## 2dh. Perbaikan bug — Hasil battle saat Chapter Clear tidak bisa diklik
- Laporan pemain: setelah menang di stage boss (akhir chapter, mis. 2-6 → 3-1), cerita menumpuk dan layar tidak bisa diklik.
- Penyebab 1: panel hasil (VICTORY + crest + bintang + hadiah 2 baris + label "CHAPTER X CLEAR!") lebih tinggi dari layar 720p, jadi tombol NEXT STAGE / CONTINUE terdorong ke luar layar.
- Penyebab 2: epilog chapter diputar lewat timer 1,6 detik, sehingga bisa muncul di atas layar story/prolog chapter berikutnya dan menumpuk dua VN.
- Perbaikan `battle.gd`: `_fit_result(v)` mengukur terhadap tinggi layar dan mengecilkan bertahap (crest disembunyikan, judul 84→60→48, bintang 64→46→36, jarak dirapatkan). Epilog kini disimpan di `_pending_outro` dan diputar oleh `_leave_with_outro` saat pemain menekan tombol apa pun selain STATS; aksi tombol dijalankan setelah epilog selesai (atau jika VN ditutup dengan cara lain, lewat `tree_exiting`).
- `story.gd _battle()`: tidak memulai dialog baru selama VN masih aktif (cegah tumpukan dari ketukan cepat).
- Diuji dengan skenario 2-6 → NEXT STAGE → epilog → story → prolog 3-1 → formation; smoke & flow PASS.

## 2di. Update batch 106 — Kartu judul chapter
- `story.gd _chapter_card()`: saat pertama kali membuka chapter baru (stage pertama = progres saat ini, bukan Hard), pita gelap membuka dari tengah, garis emas melebar, lalu "✦ CHAPTER N ✦", nama chapter besar meluncur masuk, dan nama Arc. Memudar setelah ~2,5 dtk. Tidak menghalangi klik (mouse IGNORE). Disimpan sekali per chapter di `story.seen` (`card<N>`).

## 2dj. Update batch 107 — Peta Story: medali stage & jalan emas
- `story.gd`: node stage sekarang medali (`class StageNode`): bayangan, cahaya lembut, bingkai logam berlapis, dan cincin putus-putus berputar untuk stage terpilih/berikutnya. Di dalamnya potret musuh pertama (`class CircleTex`, tekstur dipotong lingkaran; varian mirror tetap pakai shader corrupt), dengan gradasi gelap supaya nomor stage terbaca (`class StageShade`). Stage terkunci: gelap + gembok.
- Bintang di pil gelap di bawah medali, chip merah "BOSS" di stage boss, dan flag "NEXT" yang memantul pada stage berikutnya (di bawah node bila node ada di bagian atas peta, supaya tidak menabrak tombol Story Archive/Interludes).
- Jalur antar stage sekarang melengkung (bezier). Yang sudah dilewati berupa jalan emas bercahaya dengan percikan mengalir, yang belum berupa titik-titik jejak.
- Node boss digeser sedikit ke bawah (`NODE_POS[5].y` 0,30 → 0,35).

## 2dk. Update batch 108 — Story Star Chests + lentera festival
- **Star Chests** per chapter (Normal dan Hard terpisah). `DB.STAR_CHEST_NEED = [6, 12, 18]` bintang dari 18 per chapter. `DB.star_chest_reward(ch, tier, hard)`: 6★ = gold (3000+1500×ch) + 2 EXP Potion; 12★ = 40 gems + Skill Book; 18★ = 80 gems + Summon Ticket. Hard: gold, potion, dan gems ×2; 18★ Hard = 160 gems + Gear Chest + Summon Ticket.
- `game.gd`: `chapter_stars`, `star_chest_state` (locked/ready/claimed), `star_chests_ready`, dan `claim_star_chest`. Klaim disimpan di `story.chests` dengan key `n<ch>_<tier>` / `h<ch>_<tier>`. `feature_badge("story")` menghitung peti yang siap diklaim.
- `story.gd _star_bar()`: bar di kanan bawah peta, berisi "★ x / 18", jalur emas, dan 3 peti (perunggu/perak/emas) di posisi ambangnya. Peti yang siap bergoyang, dan tap untuk klaim → `show_rewards` → render ulang. Tooltip menampilkan isi hadiah.
- `festival_fx.gd _lantern()`: lentera langit festival tadinya dua kotak polos (tampak seperti kotak putih di lobby). Sekarang digambar sebagai lentera kertas: badan tong dengan rusuk, inti api bercahaya, bingkai atas/bawah, rumbai, dan ayunan pelan. Warna putih otomatis diberi tint hangat.
- `flow_test.gd`: blok `[story star chests]`.

## 2dl. Update batch 109 — Panel briefing stage yang ringkas
- `story.gd _render_detail()`: chip "STAGE x-y" / "BOSS x-y" (merah) + Lv musuh + bintang di satu baris (aturan 3★ dipindah ke tooltip bintang). Nama stage tanpa awalan "BOSS •".
- Power: bar biru (tim kamu) vs merah (musuh) dengan label SAFE (≥120%), EVEN, atau TOO STRONG. Peringatan "too weak" pindah ke tooltip bar.
- Potret musuh 48 px dengan ikon elemen. Hadiah per clear dan bonus 1ST CLEAR dalam satu kotak, masing-masing satu baris. Sekarang semua muat di atas tombol BATTLE tanpa scroll; Field Effect masih di bawahnya.
- Parameter `hard` di layar story diterima juga sebagai string "true".

## 2dm. Update batch 110 — Daily Dungeon: banner guardian
- `dungeon.gd _banner()`: banner 150 px dengan latar dungeon, art guardian (musuh terakhir di `pool`, bergoyang pelan) di kanan, nama + ikon berwarna aksen (emas/biru/oranye), deskripsi, pip ATTEMPTS, dan chip BEST. Set Armory hari ini tampil di banner.
- Level yang disarankan (tertinggi yang terbuka) diberi border emas berdenyut dan cincin emas di medali angkanya.
- Tiap level yang terbuka punya bar power (biru = tim kamu, warna = musuh). Teks "Power" diganti ikon ⚔, reward row melebar (tidak menumpuk), scroll horizontal dimatikan.

## 2dn. Update batch 111 — Starlight Rift: jalur rasi bintang & kartu guardian
- `rift.gd _rift_map()`: lantai jadi bintang 4 sudut di garis bergelombang; link yang sudah dilewati bercahaya dengan percikan berjalan, link berikutnya putus-putus; lantai guardian = bintang merah; lantai sekarang berdenyut emas dengan busur berputar; bintang latar berkelip (redraw 30 fps lewat Timer).
- `_guardian_card()`: banner 128 px dengan art guardian memakai shader varian (`UI.corrupt`), glow merah, nama besar, dan chip "N floors away" / "THIS FLOOR!".

## 2do. Update batch 112 — Expedition: SEND ALL, QUICK SEND & chibi berbaris
- `game.gd`: `auto_expedition_team(eid, taken)` (hero menganggur level terendah yang memenuhi syarat), `expedition_plan()` (rencana semua ekspedisi kosong, syarat tertinggi dulu, tanpa hero ganda), `send_all_expeditions()`.
- `expedition.gd`: tombol SEND ALL (N) di strip atas; kartu kosong menampilkan wajah tim saran (pudar, tooltip level) + tombol QUICK SEND; saat berjalan, chibi hero berjalan-bobbing di banner sesuai progres waktu.
- `flow_test.gd`: cek send-all tidak mengirim hero dua kali.

## 2dp. Update batch 113 — Tower of Trials: lantai batu
- `tower.gd _floor_row()`: pola bata (mortar tipis, warna emas di lantai sekarang, merah di lantai guardian) di belakang tiap plakat lantai.
- Lantai guardian yang belum dikalahkan menampilkan wajah guardian (musuh pertama `DB.tower_floor(f)`) di bingkai merah + tooltip nama.
- Lantai sekarang menampilkan chibi leader formasi (skin & bintang ikut) yang bergoyang.

## 2dq. Update batch 114 — Pembuka battle yang tidak menutupi papan
- `battle.gd _intro_banners()`: info SYNERGY / FIELD / LINKS / COMPANION / TACTIC / tip pertama jadi chip kecil di pojok kiri atas (titik warna + tag + isi), meluncur masuk satu per satu lalu memudar (1,6 dtk; 2,8 dtk di battle pertama). Sebelumnya bertumpuk di tengah dan menutupi unit.
- `unit_view.gd`: tween trail HP hanya dibuat saat HP turun (menghilangkan error "Tween started with no Tweeners").

## 2dr. Update batch 115 — Grafik battle (papan, unit, teks, cut-in)
- `grid_board.gd`: petak bergradasi (gelap di belakang, terang ke depan), glow luar + garis bevel, aksen sudut, rune putus-putus berputar pelan (redraw ±20 fps). Area target skill: isi glow bergradasi, bingkai dalam terang, dan garis cahaya yang menyapu.
- `unit_view.gd`: cincin dasar elips berwarna tim (biru = kita, merah = musuh, oranye = boss) dengan 3 busur berputar; bayangan lebih tegas; HP bar diberi garis segmen 25% + highlight + permata elemen di ujung kiri.
- `battle.gd _big_text()`: ROUND / FINISH! / BOSS ENRAGED! / TACTIC / ASSIST tampil di pita miring gelap dengan garis tepi berwarna, kilau yang menyapu, outline tebal + bayangan; pita membuka lalu menutup.
- `_ultimate()`: latar gradasi elemen, letterbox hitam dengan garis tepi warna elemen, lingkaran sihir berputar + heksagram + sinar cahaya di belakang hero, halftone, watermark nama skill raksasa yang bergeser; nama skill pakai outline warna elemen + bayangan.
- `_float_text()`: angka damage pakai outline berwarna (gelap dari warna angka) + bayangan; critical dapat starburst di belakang. Tag CRITICAL (atas) dan WEAK!/RESIST (bawah) kini menempel di angka (sebelumnya label terpisah yang saling tumpuk).

## 2ds. Update batch 116 — Strip urutan giliran battle
- `battle.gd _order_slot()`: tiap slot kartu wajah dengan strip warna tim (biru/merah) di bawah; unit yang sedang beraksi lebih besar (50×56), naik-turun pelan, bingkai emas + glow; unit tewas digelapkan dengan tanda X merah.

## 2dt. Update batch 117 — Panel stat hero (INFO)
- `hero_detail.gd`: header POWER besar + pill "Lv.x / cap" dengan bar level; HP/ATK/DEF memakai ikon vektor (hati, pedang, perisai) dan bar pembanding terhadap hero terkuat di level & bintang yang sama, plus nilai S/A/B/C dan tooltip persentase. Baris Bond dengan ikon hati (+ tanda OATH).
- `gacha.gd`: tombol summon yang tidak terjangkau diredupkan, teks merah tua di tombol emas (sebelumnya merah muda di atas emas, sulit dibaca) + tooltip.

## 2du. Update batch 118 — Layar hasil battle
- Judul VICTORY/DEFEAT diberi outline tebal (warna gelap dari warnanya) + bayangan.
- DEFEAT: tip pindah ke kotak sendiri dengan label TIP; tombol jadi RETRY / UPGRADE / STATS / CONTINUE dengan lebar lebih kecil — sebelumnya tombol CONTINUE dan teks tip terpotong di kanan layar.

## 2dv. Update batch 119 — Crop wajah yang tepat
- `tools/gen_face_crops.py` (baru): memindai alpha art badan penuh (rasio tinggi/lebar ≥ 1,25, plus angela, svormentis, evy_blood_sage) untuk mencari kepala → `data/face_crops.json` (237 gambar, termasuk semua outfit). `MANUAL` untuk kasus khusus (ygg_naar). Jalankan ulang setelah menambah art.
- `DB.face()`: memakai crop dari JSON berdasarkan `resource_path`; portrait setengah badan (16 hero awal) tetap memakai crop tengah-atas lama. Memperbaiki wajah yang tampil sebagai badan/kaki di strip giliran, banner Summon, hadiah shard, chat, dll.

## 2dw. Update batch 120 — Plat nama skill di battle
- `battle.gd`: plat meluncur dari sisi pelaku (kiri = kita, kanan = musuh) + kilau yang menyapu (`_banner_sheen`), nama skill pakai outline warna elemen gelap. Plat diturunkan ke y=128 (tidak menimpa strip giliran), dipersempit ke 540 px, dan diletakkan di bawah `_fx_layer` sehingga angka damage selalu terlihat di atasnya. Posisi asal dihitung ulang dari anchor tiap kali (aman saat layar di-resize).

## 2dx. Update batch 121 — Banner lobby
- `lobby.gd _show_slide()`: tepi kiri art hero diberi gradasi gelap + garis tipis warna tag, menggantikan potongan vertikal yang keras.

## 2dy. Update batch 122 — Kotak dialog cerita (VN)
- `vn_dialogue.gd`: plat nama berbentuk pita miring (StyleBoxFlat `skew`) warna tema pembicara + gelar hero sebagai subteks; kotak teks punya latar bergradasi, garis aksen warna pembicara di atas, dan garis tipis di bawah (`_box_deco`); teks dengan bayangan + jarak baris; ▼ hanya muncul setelah teks selesai diketik dan memantul di holder sendiri (tidak bentrok dengan layout VBox).

## 2dz. Perbaikan — Kartu hero terlalu zoom
- Setelah batch 119, kartu hero (tinggi) memakai crop wajah yang ketat sehingga terlihat terlalu dekat. `DB.bust()` (baru) memperlebar crop wajah ke kepala-dada (lebar ±2,1× wajah, rasio 1:1,4); dipakai `hero_card.gd` dan popup Welcome Back. Thumbnail persegi kecil tetap memakai `DB.face()`.

## 2ea. Update batch 123 — Masukan pemain (play-test teman)
- **Mailbox**: `Game.mail_list()`, `delete_mail(ids)`, `delete_read_mail()` + save `mail_deleted`. Hanya surat yang sudah di-claim yang bisa dihapus. UI: tombol DELETE READ (n) dan mode ☐ SELECT dengan checkbox per surat (ALL READ / DELETE (n) / CANCEL) + konfirmasi; inbox kosong punya pesan sendiri. Flow test `[mail delete]`.
- **Daily login**: kalender kini juga muncul untuk pemain baru (setelah dialog pembuka + panduan). Rangkaian popup awal sesi lewat `main._startup_popups()` → login → penawaran skin, masing-masing menunggu layar bersih (`_when_clear`).
- **Iklan skin baru**: `main.show_skin_promo()` — kartu layar penuh (art skin spesial yang belum dimiliki, berganti tiap hari), nama, 3 keuntungan, harga 1.280 Gems / 1 Skin Ticket, tombol GET IT ▶ (ke Wardrobe), LATER dan ✕. Sekali per hari (`promo_day`), tidak di hari pertama.
- **Ikon web PC**: favicon statis (`favicon.ico` multi-ukuran 16–64, `favicon-32.png`, `favicon-192.png`, `?v=124` untuk memaksa refresh cache) ditambahkan di shell setelah ikon engine; `publish_web.sh` menyalinnya ke `web/`. Tekstur ikon `art/` diubah dari VRAM-compressed ke lossless (VRAM ETC2 tidak didukung WebGL desktop).
- **Info role di battle**: `DB.ROLE_INFO` / `role_info()` (TANK, DPS • BRUISER/ASSASSIN/RANGED, MAGE • AoE/CURSE, SUPPORT • HEALER/BUFFER). Tap unit saat battle → kartu: wajah, nama, Lv/bintang, chip kategori role, deskripsi tugas, HP live, ATK/DEF, skill + jangkauan, passive, status. Tap lagi/di luar untuk menutup. Tip di awal battle untuk pemain baru. Chip role juga di Hero Detail.
- **Tutorial**: `game/ui/how_to_play.gd` (HowToPlay) — 7 halaman bergambar dengan diagram animasi (papan & urutan aksi, bentuk jangkauan skill, role & posisi, siklus elemen, pertumbuhan, rutinitas harian). Muncul setelah intro pertama; tombol 📖 HOW TO PLAY di Settings.
- **Bug formasi**: tap hero lain di papan sekarang hanya memilih hero itu (dulu langsung bertukar posisi). Hero terpilih pindah hanya ke petak kosong; tukar posisi lewat drag (gaya Brown Dust). Teks petunjuk diperbarui.
- **Web PC vs HP**: skala UI otomatis disamakan ke 1.15 di semua perangkat (dulu PC 1.0 → semua tampak lebih kecil dan menu samping berdesakan). Opsi manual di Settings tetap ada.

## 2eb. Update batch 124 — Kartu hero badan penuh + tag role
- `hero_card.gd`: kartu memakai art badan penuh `DB.art(id, skin)` dengan `STRETCH_KEEP_ASPECT_CENTERED` (seluruh tubuh terlihat, proporsi asli, tanpa crop/stretch) menggantikan crop wajah/bust. Tag role (TANK/DPS/MAGE/SUP, warna dari `DB.ROLE_INFO`) di bawah ikon elemen pada kartu ≥100 px.
- `export_presets.cfg`: preset Android/iOS ikut mengecualikan `_recut_backup/`, logo di root, dan favicon `web_shell/`.

## 2ec. Update batch 125 — Title screen baru
- `title.gd`: sinar cahaya berputar di belakang logo (`class Rays`) dan halo warna tema hero di belakang art; plat nama hero (gelar + nama outline warna tema + garis + rarity/elemen) di kanan bawah, meluncur masuk.
- TAP TO START di pita ornamen (`class StartPlate`): latar gelap memudar ke samping, garis emas atas-bawah, berlian berdenyut, kilau menyapu tiap 3 dtk.
- Kartu Commander: nama, Lv, jumlah hero, Power tim. Footer "v2.1 • Offline Mode" + vignette bawah.
- Tombol 📜 NOTICES (kanan atas, badge jumlah belum dibaca via `Game.news_unread()`) membuka papan pengumuman tanpa masuk game. Saat tap: logo membesar + flash.

## 2ed. Update batch 126 — Event: Sweep & penanda stage
- `Game.sweep_event(i, times)` + `Game.EVENT_ENERGY` (8, juga dipakai `pay_battle`): stage event 3★ bisa di-sweep; hadiah = menang 3★ (token + 15, gold), tanpa gem first clear; progres misi "stage" ikut. Flow test: sweep stage belum 3★ ditolak, sweep ×3 memotong 24 Energi, energi kurang ditolak.
- `event.gd`: stage berikutnya diberi bingkai emas berdenyut + pil NEXT; stage selesai berpil CLEARED / ✓ 3★ CLEAR; stage 3★ punya tombol SWEEP ×1 / ×5 (tooltip biaya & token) di bawah BATTLE. Biaya energi dijelaskan di deskripsi.
- Exchange: harga yang belum terjangkau ditulis merah tua di tombol emas (dulu merah muda tidak terbaca) + tombol diredupkan; tiap item menampilkan "Need N more" atau "✓ Affordable".
- `shot_runner.gd`: langkah `novn` menutup VN/tutorial yang terbuka (untuk screenshot layar di bawahnya).

## 2ee. Update batch 127 — Date: rekor, bonus PERFECT, gelar & tampilan baru
- **Rekor permanen** (`Game._date_state()` → `best` {hero: {spot: rank_idx}}, `count`, `perfect_paid`): `date_best(id, spot)` (0 = PERFECT, 1 = SWEET, 2 = NICE, -1 = belum), `date_count`, `date_perfects`, `date_perfect_paid`. Album tetap maksimal 60 foto; rekor disimpan terpisah. Save lama: rekor dibangun ulang dari album sekali (`DB.date_rank_index`).
- **Bonus PERFECT pertama** per hero×spot: `DB.DATE_FIRST_PERFECT` (100 Gems + 20.000 Gold), sekali saja. `finish_date` kini mengembalikan `new_best` dan `first_perfect`; popup hasil menampilkan "FIRST PERFECT AT THIS SPOT!" / "NEW BEST AT THIS SPOT".
- **Gelar baru**: SWEETHEART (PERFECT di 3 spot dengan satu hero) dan SOULMATE (PERFECT di semua spot).
- `date.gd` GO ON A DATE:
  - Daftar spot: lencana rank terbaik bersama partner yang dipilih (✦ PERFECT/SWEET/NICE atau NEW) + penghitung "✦ n / 6 PERFECT".
  - Tengah: gelembung ajakan per spot (`DB.DATE_SPOT_INFO`) yang mengambang, plat nama (gelar + nama outline warna tema).
  - Panel kanan: deskripsi spot; kartu partner (wajah, Bond Lv, jumlah kencan, bar Bond, tombol CHANGE); petunjuk kepribadian (`DB.DATE_STYLE` dari `DB.liking`: Gentle/Playful/Dreamy) yang terbuka setelah kencan pertama; tabel RESULTS (Bond + Gems per rank, ✦ di rank terbaik); kotak FIRST PERFECT HERE; hati harian ♥♡; tombol START DATE berdenyut / COME BACK TOMORROW.
- DATE ALBUM: chip filter per hero, ringkasan "n photos • ✦ n Perfect", strip spot per hero berwarna rank, popup foto menampilkan berapa hari lalu.
- `shot_runner.gd`: langkah `gcall:method|arg|arg` (panggil fungsi Game dengan banyak argumen).
- Flow test `[dates]`: bonus PERFECT pertama, tanpa bonus kedua, rekor rank terbaik, rebuild dari album, gelar Sweetheart.

## 2ef. Update batch 128 — Enemy pivot rig (idle animasi), Bestiary full body, enemy di Lobby
- **Percobaan mesh 2.5D dari Blender DIBATALKAN** (hasilnya jelek menurut user): file `.obj`, `tools/blender_enemy_25d.py`, `Model25D` dan showcase 3D sudah dihapus.
- **Pivot rig ala toko** (`game/ui/enemy_rig.gd` + `enemy_rig.gdshader`, data `DB.ENEMY_RIGS`, `DB.enemy_rig(tex)`): satu ilustrasi dideformasi di sekitar titik tumpu dengan bobot lembut (tanpa sambungan), seperti `NPCPuppet` penjaga toko tapi dengan "tulang":
  - `head` (pusat + radius masker kepala) berputar di `neck`; tubuh atas condong di `hips`; napas di `chest` (`chest_w`).
  - `bones`: [pivot x,y, ujung x,y, lebar, ayunan rad, kecepatan, fase] — bobot naik dari pivot ke ujung dan ayunan "telat" sepanjang tulang (`bone_wave`) → rambut, ekor, tentakel, sayap, lengan, sirip bergelombang.
  - `floats`: makhluk kecil yang melayang naik-turun (hantu Eroghost, slime kecil). `glows`: kilau + heat-shimmer (mata menyala, bola api, orb). `head_band = 0` untuk pose terbalik (Lizamorph, Ygg-Naar).
  - **Kedipan**: kelopak atas asli (dengan bulu mata) digeser turun dan kulit di atasnya meregang — tidak ada tempelan warna, poni/tato tetap utuh. Dimatikan untuk mata menyala / tertutup (Gumi, Evy, Eroghost, Lizamorph, Ygg-Naar).
  - Idle berlapis: napas + bob, sway badan, kepala melirik ke arah acak tiap 3,5–7 detik, kedip (kadang dua kali), per-rig `speed` / `head_amp` / `body_amp`. `react(ry)`: kepala = angguk malu + kedip, badan = tersentak, kaki = semua tulang tersentak. Reduce-effects → gerak 40%.
  - Terpasang di Bestiary (art tengah), Lobby (enemy sekretaris), Art Viewer (lensa). Art yang punya pivot rig tidak lagi memakai tilt depth otomatis (`DB.live_rig` → {}); form lain tetap memakai tilt depth.
  - 16 enemy (form dasar / stage1) sudah di-rig dari grid koordinat + crop wajah. Alat cek: `tools/rig_preview.gd` (4 momen + overlay pivot/tulang) dan `tools/rig_face.gd` (close-up wajah: diam vs kedip+tengok).
- **Bestiary**: grid **full body** (kartu 110×172, latar warna elemen), area galeri tengah diperlebar (34,5%–70,5%), strip form/evo full body 70×100, tombol **🏠 SET AS LOBBY**.
- **Enemy di Lobby**: `Game.lobby_enemy()` / `lobby_enemy_form()` / `set_lobby_enemy(id, form)` (harus sudah dikalahkan). Tap = zona kepala/badan/kaki + efek + dialog (`DB.enemy_lobby_line`: dialog bond kalau dijinakkan, `DB.RIVAL_LINES` kalau belum), head-pat untuk foe jinak. Pill: ♥ TALK, FORM, SCENE, FORTUNE, ◆ VIEW (lensa), ⇄ HERO; swipe kembali ke hero.
- `tools/shot_runner.gd`: langkah `kills:<enemy>|n`.
- Flow test: `[lobby enemy]` + semua enemy punya live rig (pivot atau depth), pivot rig hanya mengganti tilt pada art yang di-rig.

## 2eg. Update batch 129 — Hunter's Lore (bonus battle dari Bestiary)
- Setiap milestone bestiary (10 / 50 / 150 / 400 kill) = 1 level **Hunter's Lore** melawan enemy itu: `DB.LORE_DMG` +3% damage ke dia dan `DB.LORE_GUARD` −2% damage dari dia per level (maks +12% / −8%). Varian (hollow:/echo:/…) ikut memakai lore enemy dasarnya.
- `Game.lore_level(id)`, `Game.lore_map()` → `BattleSim.lore` (battle sungguhan + simulasi auto/sweep). Damage dihitung di `_act` setelah GUARD.
- Battle: chip "HUNTER'S LORE: …" di pojok kiri atas kalau ada enemy yang lore-nya sudah naik.
- Bestiary (tab INFO): kartu HUNTER'S LORE (◆◇ level, bonus sekarang, bar + kill yang kurang ke level berikut, "Lore mastered").
- Flow test `[hunter's lore]`: level dari kill, varian, lore map, damage sekutu naik dengan lore.

## 2eh. Update batch 130 — Rig pivot untuk 37 hero + kedipan presisi (hero & enemy)
- `EnemyRig` → **`CharRig`** (`game/ui/char_rig.gd` + `char_rig.gdshader`) untuk hero DAN enemy. `UI.live` memasangnya otomatis di setiap art hidup (lobby, hero detail, viewer, bestiary, dll.). `DB.char_rig(tex)` mencari di `DB.HERO_RIGS` lalu `DB.ENEMY_RIGS`. Ekspresi alternatif (`_a`, `_altN`) memakai rig badan pose dasarnya tanpa kedip. Art yang punya pivot rig tidak memakai tilt depth (`DB.live_rig` → {}). Varian corrupt/mirror tidak disentuh.
- **`DB.HERO_RIGS`**: art dasar (stage1) dari ke-37 hero di-rig (kepala/leher/pinggul/dada, tulang rambut, sayap, ekor, tentakel, rantai/senjata, makhluk melayang, kilau) dan dicek lewat overlay `tools/rig_preview.gd`.
- **Mata diukur presisi** pada crop close-up (grid 0,0025 UV) lalu diverifikasi dengan overlay elips (`eyes: [[sudut x,y, sudut lain x,y, kelopak atas y, kelopak bawah y], …]`; `[]` = mata tertutup rambut). 35 hero + 11 enemy punya kedipan. Mata menyala/tertutup topeng tidak berkedip.
- **Kedipan baru (Live2D-style)**, dihitung per-mata di ruang lokal mata (kemiringan dari kedua sudut):
  - Garis bulu mata atas yang asli ikut turun mengikuti busur mata (sudut menutup lebih dulu) dan berhenti sebagai garis tertutup melengkung (`lid_close`).
  - Kelopak yang terbuka diisi kulit kelopak asli dari atas bulu mata yang direntangkan (eyeshadow ikut). Kalau di situ ada rambut atau alis, otomatis memakai warna kulit (rata-rata sampel pipi yang paling mirip kulit). Ada lipatan kelopak dan bayangan di bawah bulu mata.
  - Semua tepi di-feather. Timing: menutup cepat 0,07 dtk, tahan sebentar, membuka pelan; kadang kedip dua kali.
- `react(ry)` dipanggil saat tap di lobby (hero & enemy), hero detail, viewer, bestiary.
- Alat: `tools/rig_face.gd` (close-up mata: buka / setengah / tutup / tengok + titik ukur), `tools/rig_preview.gd` (overlay pivot/tulang, hero atau enemy).
- Flow test: semua hero punya rig, ≥34 hero punya mata terukur, Glytta evo2 tetap rig buatan tangan.

## 2ei. Update batch 131 — Rig pivot untuk semua outfit / evolusi / special / lobby
- **`data/char_rigs.json`** (160 art): rig pivot untuk semua art hero selain stage1 (stage2+, evo1+, special, lobby, plus Lucidria evo1_a/_b yang tidak punya base). Dimuat lazy oleh `DB.form_rigs()` (array JSON → Vector3/Vector2/Color).
- **Cara bikin**: wajah stage1 dicari di tiap art dengan template matching multi-skala (OpenCV), rig stage1 ditransformasi ke art itu, lalu tiap mata disempurnakan sendiri (pencarian skala + rotasi di sekitar posisi tebakan). Semua hasil dicek visual lewat overlay (badan + close-up mata).
  - Pose sama → rig penuh ikut (tulang, floats, glow). Pose beda → floats/glow dibuang, hanya tulang dekat kepala yang dipertahankan.
  - 36 art berpose beda total → kepala/leher/dada/pinggul/tulang ditandai manual dari grid.
  - Mata: 95 outfit berkedip. Mata menyala, hati, spiral, kaget lebar, atau yang tidak terlacak akurat → tanpa kedip (ekspresi aman, tidak ada kelopak meleset). Kotak mata hasil otomatis diberi margin ekstra (bawah +22%) supaya iris tertutup penuh.
- **`DB.char_rig`**: ENEMY_RIGS → HERO_RIGS → form_rigs. Ekspresi alternatif dipetakan ke base outfit-nya lewat `interactions` di character_database (bukan cuma regex `_a/_altN`, sekarang juga `_b/_c`) dan memakai rig base tanpa kedip.
- Glytta evo2 tetap memakai rig 2.5D buatan tangan.
- `tools/rig_face.gd` sekarang menerima indeks art (`-- out.png <id> <index>`).
- Flow test: 192/192 outfit + ekspresi alternatif punya rig, ≥120 outfit bermata terukur, pose lobby memakai rig pivot.

## 2ej. Update batch 132 — Rig pivot untuk semua form enemy + pembersihan art
- **46 form enemy** (stage2+, evo, lobby Hairly/Ymir) masuk `data/char_rigs.json` (total 206 art). Enemy dengan mata terukur memakai pencocokan wajah + mata. Enemy tanpa kedip (Eroghost, Evy, Gumi, Ygg-Naar) dicocokkan lewat area kepala. 9 form berpose beda (Eroghost stage2/evo1/evo2, Gumi evo2–6, Hairly evo2) ditandai manual.
- 18 form enemy berkedip. Mata spiral, kaget lebar, atau tidak akurat dibiarkan tanpa kedip.
- `DB._inter_base` sekarang juga memetakan ekspresi alternatif milik enemy.
- **Pembersihan art**:
  - `scylla_char_evo2`: pola checker yang ikut tergambar di antara kaki dibuat transparan, termasuk sisa serpihannya di dekat tali sepatu.
  - `zennyo_char_evo3/evo4`: gumpalan latar putih di antara lengan dan sayap dibuat transparan, dengan tepi di-unmix supaya tidak ada halo putih.
  - Backup ada di scratchpad sesi (`bak132/`). Zennyo evo2 tidak diubah karena putihnya inti bola api.
- Deteksi checker baru (dua tone abu/putih yang rata dan bersebelahan dengan area transparan) sudah dijalankan ke 324 art. Tidak ada checker lain yang ditemukan.
- Flow test: semua form enemy punya rig pivot (60/60). Art tanpa rig (Glytta evo2_a) tetap memakai depth tilt.

## 2ek. Update batch 133 — Perbaikan kedipan dari feedback user
Feedback: kedipan aneh di Fidelia, Angela, Tamo, Kali, Kara, Atalanta, Seraph, Zennyo, Micca, Gala, Scylla, Hyeonxa, Lumeira, Mora, Ex-Nymph. Luby/Schylua belum berkedip. Wajah Cthollia ikut bergelombang. Mata Evy bergelombang. Ygg-Naar belum berkedip, dan mata di ekornya harus berkedip dengan tempo berbeda.
- **Warna kelopak**: warna kulit diukur sekali per art di CPU (`CharRig._eye_skins`) dari pipi di bawah mata, di sisi hidung. Median warna dipakai supaya helai rambut tidak ikut terhitung. Di shader, `ring_skin` mengambil 10 sampel di cincin sekitar mata dan hanya memakai sampel yang mirip kulit tadi (rambut, bulu mata, alis, dan highlight dibuang), lalu dibobot jarak. Hasilnya kelopak menyatu dengan kulit di semua sisi.
- **Rambut tetap di depan**: di luar bukaan mata, kelopak hanya menimpa piksel bulu mata atau kulit. Helai rambut yang melintas tidak ikut tertutup.
- **Cakupan**: kelopak naik menutupi bulu mata atas yang tergambar. Saat hampir tertutup, kelopak bawah ikut naik (`low`), jadi garis air mata, bagian putih mata, dan bulu mata bawah tidak menyisakan outline.
- **Wajah tidak bergelombang**: tulang (rambut/tentakel), floats, dan heat shimmer dimask keluar dari area wajah (`keep` = 1 − mask kepala). Ini memperbaiki Cthollia dan shimmer di mata Evy.
- **Banyak mata**: shader menerima `eyes[8]`, `eye_rots[8]`, `blinks[8]`, dan `skins[8]`. Dua mata pertama adalah pasangan wajah. Mata tambahan (ekor/makhluk) punya timer kedip sendiri (1,8–6,5 detik, kedip lebih lambat). Ygg-Naar: mata visor dan 6 mata ekor.
- **Mata baru diukur**: Luby, Schylua (`skin_hint` biru untuk kulit non-manusia). Kara dipersempit ke bagian mata yang terlihat, Angela kiri diperlebar.
- `tools/rig_face.gd` sekarang mengisi `blinks` untuk semua mata.

## 2el. Update batch 134 — QA kedipan semua art
- Semua 162 art yang punya mata dirender buka/tutup (`tools/rig_face.gd` sekarang juga menerima path `res://`), lalu dicek per contact sheet.
- **Satu wajah, satu warna kulit**: di beberapa art, pengukuran pipi salah satu mata kena bayangan, helai rambut, totol rias, atau cahaya mata, sehingga kelopaknya abu-abu atau gelap. Contohnya Voodoo, Skelinch, Svormentis, Rumi evo1, Lucidria stage2, dan Lumeira stage1. Sekarang `_eye_skins` membandingkan kedua mata. Kalau beda jauh (>0,12), nilai yang paling mirip kulit (terang + hangat) dipakai untuk keduanya.
- **Shader menahan drift**: hasil `ring_skin` ditarik kembali ke warna kulit terukur atau `skin_hint` kalau menyimpang (0,06–0,18). Kelopak tidak lagi abu-abu di mata bercahaya (misalnya Glytta stage1 dan Svormentis).
- **Kotak mata diperbaiki**: Skelinch diukur ulang (mata kiri sebelumnya bergeser, mata kanan terlalu kecil). Kotak Eropatra stage2/3/evo1–3 dipendekkan 28%. Kotak Svormentis stage2/evo1 dipendekkan ke bukaan mata karena silau mata ikut terhitung.

## 2em. Update batch 135 — kedipan wajah merona
- Masalah: pada art dengan rona pipi tebal, sampel kulit di sekitar mata ikut kena rona, sehingga kelopak yang menutup menjadi petak oranye atau merah. Ini terjadi pada Eropatra stage2/3/evo1–3, Lumeira evo1/evo2 dan Glytta stage2.
- `data/char_rigs.json` sekarang menerima `skin_hint` `[r,g,b]` (warna kulit wajah tanpa rona, dipilih dari piksel kulit paling tidak merah di sekitar mata) dan `blush` `[r,g,b,kekuatan]` (median piksel rona di bawah mata, kekuatan 0,85). `DB.form_rigs()` mengubah keduanya menjadi `Color`.
- Shader `char_rig.gdshader`: uniform baru `blush`. Di akhir `ring_skin`, warna kelopak dibaurkan dari kulit (atas) ke rona (bawah) dengan `smoothstep(-1.3, 0.7, q.y)`, jadi kelopak tertutup menyambung dengan pipi. `char_rig.gd` mereset `blush` ke 0 untuk rig yang tidak memakainya.

## 2en. Update batch 136 — Sprite chibi Mora, Ex-Nymph, Ygg-Naar
- Ketiganya sebelumnya tidak punya sprite chibi, jadi di battle, formation, tower dan lainnya memakai artwork penuh (kecil, kepala mungil, tidak serasi dengan unit lain).
- `tools/chibify.py` (baru) membuat sprite chibi dari artwork penuh: kepala diperbesar 1,55–1,85× dengan warp bulge halus (pusat dan radius dari posisi wajah), lalu badan di bawah garis pinggul dipendekkan ke 62–75%. Hasilnya di-crop dan disimpan dengan tinggi maksimal 1000 px (import `size_limit=512`, sama dengan sprite lain).
- Sprite baru:
  - `heroes/mora/sprite/mora_sprite_stage1.png` dan `mora_sprite_evo1.png` (dipakai mulai 5★)
  - `enemies/ex_nymph/sprite/ex_nymph_sprite_stage1.png`
  - `enemies/ygg_naar/sprite/ygg_naar_sprite_stage1.png` dan `ygg_naar_sprite_evo1.png` (dipakai saat jadi boss lewat `DB.boss_sprite`)
- Didaftarkan di `sprites` pada `data/character_database.json`, jadi semua pemanggilan `DB.sprite()` / `DB.boss_sprite()` langsung memakainya.

## 2eo. Update batch 137 — Arc 11: The Frostbound Crown
- **4 chapter cerita baru (41–44, 24 stage; total 44 chapter / 264 stage).** Mahkota Musim Dingin Frostvale bangun dan mencari ratu yang "tak pernah mencair".
  - **Ch.41 Frostvale Pass** (map `ice`): bosnya Frostbound Schylua, penjaga brankas mahkota.
  - **Ch.42 Aurora Observatory** (map `galaxy`): bosnya Frostbound Micca. Ia "dititipi" kotak oleh wanita berbaju putih.
  - **Ch.43 The Glass Sea** (map `aqua`): bosnya Frostbound Aqua, dibantu Cthollia.
  - **Ch.44 Throne of Frostvale** (map `ice`): bos finalnya Frostbound Valeria.
  - Tiap chapter punya intro, mid, mid2, boss_lines, outro, pilihan VN (bond), dan field effect sendiri. Kebanyakan berupa bonus FIRE, karena "mencairkan es".
- **Varian musuh baru `frost`:** prefix speaker `frost:`, nama "Frostbound X", warna tema biru, label battle "FROSTBOUND". Tampilannya biru es pucat dengan outline putih-biru.
  - Shader `corrupt.gdshader` dan `live25d.gdshader` mendapat uniform `tone`. Warna grey-scale untuk `desat` sekarang bisa diatur; defaultnya tetap sepia, jadi varian lama tidak berubah.
  - Varian ini juga masuk `RIFT_VARIANTS`.
- **Interlude i11 "Cocoa After the Thaw"** terbuka setelah 264 stage.
- **Mail "Arc 11"** berisi 30.000 Gold, 5 EXP Potion, dan 2 Energy Potion. Sengaja tanpa gems/tiket supaya ekonomi hari pertama tetap 12–20 summon.
- **Balancing:** pool musuh ch42 dan ch44 dibuat tanpa Hairly/Svormentis ganda, dan multiplier bos Micca/Valeria diturunkan. Dengan tim uji standar Lv.100, win-rate bos: 85% / 60% / 65%, lalu final tetap berat (setara Arc 10).
- **Perbaikan:** chapter 39–40 (Arc 10) sebelumnya masuk tab "ARC 9" dan berlabel "THE WILD HUNT". Sekarang ada tab ARC 10 dan ARC 11, dengan nama arc yang benar di peta dan Story Archive.

## 2ep. Update batch 138 — Gelar & hadiah arc, link "After the Thaw", Frostbound di battle
- **Gelar Commander baru** (`DB.TITLES` + `Game.title_unlocked`):
  - Gatebreaker (Arc 8, 204 stage)
  - Master of the Hunt (Arc 9, 228)
  - Conductor of the Abyss (Arc 10, 240)
  - Crownbreaker of Frostvale (Arc 11, 264)
  - Sebelumnya gelar arc berhenti di Arc 7.
- **Achievement baru:**
  - Clear Arc 10: 10.000 Gems, 20 tiket, 1 Oath Ring.
  - Clear Arc 11: 16.000 Gems, 30 tiket, 7 Celestial Gem.
  - Recruit all 37 heroes: 5.000 Gems dan 1 Special Skin Ticket. Skin Ticket di Bag sekarang mencantumkan Achievements sebagai sumbernya.
- **Story Link "After the Thaw"** (Valeria + Rubby + Aqua): ATK/HP/DEF +5%.
- **Frostbound terbaca jelas:**
  - Tone es diperkuat (`tone` 0.74/1.08/1.62).
  - Di battle, bos Frostbound memakai modulate dingin (0.8, 0.95, 1.2), bukan tint hangat bos yang menetralkan biru pada outfit putih.
  - `shot_runner` `matprobe` kini juga mencetak `tone`/`desat`.

## 3. Yang BELUM ada (butuh keputusan/aset tambahan)

- **Online sungguhan** (akun, server, PvP real-time, guild, chat, anti-cheat): butuh backend (mis. Nakama, PlayFab, Firebase). Saat ini semua lokal (offline).
- **Pembayaran / top-up uang asli**: belum ada; shop memakai Gems/Gold/Arena Coin.
- **Friend, Guild & Event** sudah ada, tapi teman/anggota masih simulasi (belum multiplayer).
- **Voice acting** & rig Live2D/Spine asli: semua art sudah bergerak gaya Live2D lewat rig pivot (`char_rig`: napas, kepala, rambut/ekor, kedip). Mesh deformasi Live2D/Spine sungguhan dan file suara belum ada.
- Musuh di `enemy/Belum bisa dipakai` tidak dipakai.

## 4. Struktur kode baru (`game/`, ±5.800 baris)

```
game/
  main.tscn / main.gd      router layar + popup, toast, reward, dialog cutscene
  core/db.gd               SEMUA data: hero, skill, musuh, stage, gacha, shop, quest, mail
  core/game.gd             autoload "Game": state pemain, save/load, ekonomi, progres
  core/battle_sim.gd       simulasi battle Brown Dust (deterministik → daftar event)
  ui/ui.gd                 tema & komponen UI bersama
  ui/grid_board.gd         grid 3x3 perspektif
  ui/unit_view.gd          unit chibi (sprite, HP bar, nomor urut)
  ui/hero_card.gd          kartu hero
  ui/shape_preview.gd      diagram jangkauan skill
  ui/screen.gd             base class layar (header, chip mata uang)
  screens/                 lobby, heroes, hero_detail, formation, story, battle,
                           gacha, shop, bag, quests, mail, arena, tower, settings
tools/
  flow_test.gd             tes otomatis logika game (47 cek)
  balance_test.gd          win-rate tim vs semua stage
  shot_runner.gd           screenshot otomatis semua layar
```

## 5. Cara pakai

- Buka project di Godot 4.7 → Play. Scene utama: `res://game/main.tscn`.
- Versi lama tetap utuh: buka `main_legacy.tscn` (atau `main.tscn`) dan Run Current Scene.
- Tes logika: `Godot --headless --path . -s res://tools/flow_test.gd`
- Balancing: ubah angka di `game/core/db.gd` (stat hero, skill `mult`, `stage()`, rate gacha).

### Menambah hero baru
1. Taruh art di `art/characters/heroes/<id>/char|sprite` dan daftarkan di `data/character_database.json` (format sama seperti hero lain).
2. Tambahkan entri di `DB.HEROES` (rarity, role, hp/atk/def, skill: aim, shape, mult, efek).
3. (Opsional) tambah voice line di `DB.HERO_LINES`.

## 2gm. Intro logo studio (ONIX Studio)

- Urutan masuk: unduhan (shell web) → boot splash engine → **intro ONIX Studio** → layar judul.
- `art/brand/onix_intro.png` (1280×720): logo versi gelap dari `ONIX/onix studio logo aps/BLACK_ONIX_LANSCAPE.JPG`, dipotong ke area logo, lebar 640 px (50% layar), tepi dilebur ke warna datar `#09090d`.
- Boot splash engine memakai gambar dan warna latar yang sama, jadi tidak ada lompatan antara splash dan intro. Splash lama disimpan sebagai `art/brand/boot_splash_euphoria_backup.png`.
- `game/ui/studio_intro.gd` + `studio_intro.gdshader`: jeda 0,35 dtk, sapuan cahaya 0,95 dtk (hanya mencerahkan bagian krom), zoom halus, pudar 0,55 dtk; total ±2,5 dtk; ketuk untuk lewati; Reduce effects = tanpa sapuan. Ditambahkan di `main._ready` di atas layar judul yang sudah siap.
- Tes: `shot_runner` melewati intro (meta `no_intro`); `INTRO=1` untuk menampilkannya.

## 2gn. Web: landscape saja (tanpa tampilan portrait)

- Semua tampilan portrait di shell web dihapus: layout loading portrait (`@media (max-aspect-ratio: 1/1)`), layar "Putar ponselmu" (`#rotate-hint`) dan teks `#ld-rotate`.
- **Halaman diputar 90°** saat perangkat sentuh dipegang tegak (`html.rot`, `eoFit()` di `<head>`): canvas dan layar loading memakai bingkai landscape `--lw × --lh` lalu di-`rotate(90deg)`. Ukuran di CSS loading kini memakai `--lw/--lh` (bukan `vw/vh`), sehingga proporsinya sama di layar tegak maupun miring; layar pendek (≤ 330 px) memakai kelas `html.short`.
- **`tools/web_landscape_patch.py`** (dijalankan `publish_web.sh`) menambal engine hasil export di 3 titik: ukuran canvas mengikuti bingkai landscape, posisi tap/sentuh dan gerak relatif dipetakan balik lewat rotasi. Skrip gagal keras bila kode engine berubah setelah upgrade Godot.
- Android: ketukan pertama meminta fullscreen + `screen.orientation.lock('landscape')`. iOS tidak punya API itu, jadi halaman tetap diputar.
- Logo ONIX, layar judul dan game memakai stretch `canvas_items` + `expand`, jadi otomatis pas di rasio landscape apa pun.

## 2go. Masuk game: gerbang "KETUK UNTUK MASUK", suara logo, judul tanpa musik

- **Gerbang setelah unduhan** (shell web): saat engine siap, layar loading menampilkan "Siap!" dan tombol **KETUK UNTUK MASUK** (atau ketuk di mana saja). Ketukan itu: (1) membangunkan audio engine di dalam gestur (`window.__eoAudio`, ditambal oleh `web_landscape_patch.py`), (2) di Android meminta fullscreen + mengunci landscape, (3) menyetel `window.__eoEntered` — `studio_intro.gd` menunggu flag ini (`JavaScriptBridge.eval`) sebelum logo muncul. Browser melarang suara/fullscreen tanpa sentuhan pengguna, itu sebabnya logo dulu senyap dan HP tegak tidak bisa layar penuh.
- iPhone (Safari, bukan mode Layar Utama): catatan cara layar penuh (Bagikan → Tambahkan ke Layar Utama). iOS tidak punya API fullscreen/kunci orientasi untuk halaman.
- **Bingkai landscape dari `visualViewport`** (`window.__eoFrame`), dipakai halaman dan engine; halaman dikunci `position: fixed` + `overscroll-behavior: none` supaya tidak memantul / bergeser saat bar browser bergerak.
- **Suara pembuka logo**: `audio/ui/studio_open.wav` (2,8 dtk; swell rendah, akord kaca A–E, kilau tinggi, ekor udara) dari `tools/gen_ui_audio.py`.
- **Musik**: tidak ada BGM di logo dan layar judul (`BGM["title"] = ""` → `Game.stop_bgm()`); lagu lobby mulai saat masuk game.
- Pemetaan sentuhan saat halaman diputar diuji di Node dengan 5 titik (semua kembali tepat).

## 2hq. Update 15 Nov — 17 musuh baru + 2.5D di semua pivot rig

- **Impor** (`tools/import_nov15.py`): 17 musuh dari `Karakter Euphoria Online/enemy/New Enemy Update 15 nov /` → `art/characters/enemies/<id>/` (70 form + ekspresi alternatif, 51 sprite). ID: amatera, anthis, cleara, code_zero, cow_girl, graeae, kurenai, lamia, lolth, nagini, nox, octavia, rin, roza, selene, veyr_nok, xaniyus.
- **Build** (`DB.ENEMIES`): stat, peran dan skill mengikuti art — mis. Code Zero TANK (pierce + shield + taunt), Kurenai ASSASSIN (execute), Nagini MAGE (kolom + stun), Selene (back line + drain 50%), Lolth (all + silence), Roza RANGER (pierce + crit), Rin (line + heal block), Veyr-Nok (X + DEF down).
- **Kemunculan**: ditambahkan ke pool 28 chapter (ch. 15–52), `RIFT_POOL`, Tower (otomatis dari `ENEMIES`), Bestiary + taming (`PET_LINES`, 5 baris per musuh). Training Ground kini punya partner LIGHT (Roza); ubin rekor pindah ke kolom kiri bila partner 6.
- **Pivot rig**: 70 rig diukur per art (kepala, leher, dada, pinggul, hingga 10 tulang, floats, glows, mata) → `data/char_rigs.json` lewat `tools/merge_dev_rigs.py`; face crop diambil dari lingkar kepala rig (pose menunggang/terbalik jadi benar). Diperiksa dengan `tools/rig_preview.gd` (kini menerima path art) dan `rig_face.gd`. Kedipan dimatikan untuk Xa'niyus (5 form), Lolth stage1 dan Lamia evo1 karena kelopak tampak seperti tambalan; 6 art lain memang tanpa mata terlihat. File rig mentah: `_recut_backup/rigs_dev_nov15/`.
- **2.5D untuk semua art ber-rig** (`char_rig.gdshader` + `char_rig.gd`): putaran kartu mengikuti pointer/orbit idle, parallax dari depth map (`art/depth`), cahaya kunci, cahaya tepi dan bayangan jatuh. Sebelumnya art ber-rig tidak mendapat lapisan depth sama sekali. `LiveRig.backdrop` juga bekerja untuk art ber-rig.
- Flow test: bagian "[15 Nov enemies]"; cek rig musuh kini lewat `DB.char_rig` (rig tangan di db.gd atau JSON).

## 3c. Batch 261 (20 Nov 2026): tanpa kedip untuk Sharas, Yumi, skin Angela/Mei/Eropatra/Rubby
- Owner menilai semua metode kedip (kelopak geser, kelopak lukis, gambar mata tertutup, tracing per mata) pada 6 karakter ini jelek; tracing per mata (bukaan mata + bulu mata dari piksel) dicoba dan hasilnya lebih buruk (garis bergerigi, isian kotak-kotak). Sesuai izin owner ("kalau tidak memungkinkan gausah kedip"): `eyes = []` dan tanpa lid untuk semua form Sharas & Yumi dan semua pose 4 skin (51 art). File `art/lids/` yang tidak terpakai dihapus (40 tersisa). Gerak napas/rambut/tilt 2.5D tetap.

## 3b. Batch 260 (20 Nov 2026): kedipan "swap" (gambar mata tertutup) untuk Sharas, Yumi, skin Angela/Mei/Eropatra/Rubby
- User masih menilai kedipan 6 karakter ini jelek. Ganti metode: `tools/make_lids.py` (`draw_closed`) melukis gambar mata tertutup jadi per art (isian kulit + garis bulu mata anti-alias yang melengkung, tebal di tengah dan meruncing di sudut, warna bulu mata asli, bayangan tipis). Rig `lid_swap: 1` → `char_rig.gdshader` hanya cross-fade ke gambar itu (`smoothstep(0.12, 0.72, blink)`), tanpa animasi kelopak setengah. 51 art (semua form Sharas & Yumi, semua pose 4 skin) dicek di contact sheet sebelum dipasang, lalu di Godot (`tools/blink_frames.gd`).
- HERO_RIGS sekarang ikut menyimpan `lid_swap` / `lid_slide`.

## 3a. Batch 259 (20 Nov 2026): kedipan "kelopak geser" untuk Sharas, Yumi, Vila, skin Angela/Mei/Rubby
- `char_rig.gdshader`: dengan painted lid (dan `lid_slide` = 1, default) kedipan memakai alur baru: garis bulu mata gelap (`lashc_dark`, sampel bulu mata asli, maks 32% kecerahan kelopak) turun mengikuti busur mata; di atasnya tampil tekstur kelopak (alpha = area mata yang dihapus), jadi bulu mata asli hilang tepat di tempat garis baru lewat, tanpa bulu mata ganda. Bayangan lipatan tipis di atas garis, kelopak bawah naik di akhir. Batas area per mata diperlebar (lid tidak terpotong).
- `tools/make_lids.py`: isian = difusi multi-skala dari kulit di sekitar mata saja (cincin kulit, tanpa rambut/bulu mata/putih mata), kecerahan disamakan dengan tepi lubang; komponen gelap yang sebagian besar di luar zona bulu mata (rambut) tidak dihapus; putih mata di luar bukaan ikut dihapus; alpha di-feather lebar. Opsi rig `lid_paint` (Telea), `lid_keep` (lid tidak dibuat ulang), `lid_slide: 0` (cara lama; dipakai Toka karena hasil lama lebih baik).
- Yumi stage1: mata kiri diukur ulang. Alat: `tools/blink_frames.gd` (5 tahap kedip per art, `ZOOM`).

## 2zz. Batch 258 (20 Nov 2026): ekspresi alternatif berkedip, kelopak tanpa kubah
- 14 ekspresi alternatif hero baru (Aura, Fuji, Kyra, Sharas, Toka, Tora, Vila, Yumi) punya rig sendiri hasil transfer dari form dasarnya, jadi ikut berkedip (sebelumnya alt tanpa kedip).
- Skin Eropatra pose alt6–11 diukur manual dan berkedip; semua 15 pose skin Eropatra berkedip.
- Tora: mata kedua semua form diukur (stage1 kanan digeser, stage2/evo1–3 kiri ditambah); `lid_tone` untuk form bercahaya hijau. Yumi: mata kiri semua form digeser ke posisi sebenarnya.
- Shader: dengan painted lid, tepi atas kelopak memudar sangat lembut (`smoothstep(top - 1.1, top + 0.1)`) dan gradasi gelap ke bulu mata dikurangi (0,97) → tidak ada garis "kubah" (Vila, Sharas).

## 2yy. Batch 257 (20 Nov 2026): kelopak lukis, kedipan semua form, cut-in terang, Wardrobe bisa dipencet, loading = maps
- **Wardrobe**: cahaya `rays.png` yang berputar memblokir klik tombol → `mouse_filter = IGNORE` (juga di Forge).
- **Cut-in ultimate gelap**: `cutin_fade.gdshader` mengalikan warna tekstur dua kali (COLOR di Godot 4 sudah berisi tekstur×modulate). Sekarang hanya alpha yang di-fade; kecerahan kembali sama seperti sebelum batch 255 (diukur: 134.8 → 135.1).
- **Loading download**: hanya peta (10 map, `tools/make_maps_loading.py` → `web_shell/loading/map_*.jpg`); hero dan file `hero_*.webp`/`bg_<hero>.jpg` dihapus dari shell.
- **Kedipan "painted lid"**: `tools/make_lids.py` membuat crop sekitar mata dengan mata + bulu mata atas di-inpaint (OpenCV Telea + blur, alpha = area yang dihapus) → `art/lids/<art>_lid.png`, rig mendapat `lid: [path, x, y, w, h]`. `char_rig.gdshader` (`lid_tex`, `lid_rect`) mengambil warna kelopak dari situ, jadi bayangan, blush, dan rambut tipis tetap ada. Dengan lid, sudut mata dan tepi bawah ikut tertutup (`side_l`, `inside_l`). Opsi rig `lid_tone` (Sharas, Vila) mengembalikan isian keruh ke warna pipi.
- **Semua form berkedip**: Kyra stage2/3, Tora stage2/evo1-3 (mata yang terlihat), Sharas semua form (mata kedua ditambah), Yumi semua form, Toka evo1, Vila evo1, Fuji stage2; skin Eropatra (base, alt1-5, alt12-14), Angela alt3, Mei (mata kiri diperbaiki), Rubby. Pose alternatif skin Eropatra alt6-11 (pose beda) tanpa kedip.
- Alat: `tools/blink_sheet.gd` (8 art: buka/tutup; `ZOOM=0.3` = skala game), `tools/rig_motion.gd`.

## 2xx. Batch 255 (20 Nov 2026): rarity baru, skin jadi evo terakhir, Glytta bersih, kedipan & 2.5D hero baru
- **Rarity** (dokumen "Rarerity Hero 16 nov 2026.docx" versi 20 Nov): Sven SSR→LR, Eropatra SSR→UR, Tamo LR→UR, Tora LR→SSR, Vila SSR→SR, Vexira SR→N. Rate: LR 0,01%, MR 0,001%, GR 0,0001%, OR 0,00001% (`DB.RARITY_RATE`); `gacha.rate_text` kini 6 desimal. Pity 80 tetap memberi LR. Dokumen menulis Tsundae di SR dan R; dipakai SR.
- **Wardrobe**: skin spesial Ning Er, Spimei, Luby, Morana, Tamo dipindah ke state `evo<n>` terakhir (file `*_char_special.png` → `*_char_evo<n>.png`, rig/face crop/depth ikut). Index outfit tidak berubah, jadi save yang sudah membeli tetap terbuka lewat `skins_bought`. `DB.SPECIAL_SKINS` sisa 5 (Hyeonxa, Angela, Mei, Eropatra, Rubby); slide lobby WARDROBE memakai Eropatra.
- **Glytta**: 7 art baru tanpa background (sumber `hero/Glytta/*.png`, 18 Nov) dijajarkan (ORB + similarity transform) ke kanvas art lama supaya rig/crop/depth tetap pas; sprite dibuat ulang dari art bersih.
- **Kedipan hero baru**: semua mata diukur ulang dari zoom 0,002 UV dan diverifikasi dengan overlay elips (`/tmp` eyecheck: elips = yang dipakai shader) lalu `tools/rig_face.gd`. Param rig baru `lid_reach` (shader `char_rig.gdshader`): batas atas kulit kelopak untuk mata besar dengan poni dekat di atas (Toka 0,45, Kyra/Aura/Sharas/Vila/Tora/Fuji 0,6). Tanpa kedip: Yumi (pupil simbol, mata tertutup poni), Fuji stage2 (spiral), Sharas stage2 (mata menyala), Tora evo, Vila evo1.
- **2.5D**: ayunan tulang lentur (rambut/sayap/ekor, swing ≥ 0,012) ×1,45 maks 0,034, setara Shina; tulang rambut Tsundae digeser supaya tidak menarik gaun saat disentuh. Alat baru `tools/rig_motion.gd`.
- **Cut-in ultimate**: art memudar 46–58% lebar layar (`game/ui/cutin_fade.gdshader`), tidak terpotong garis lurus.
- Tes: flow_test PASS, `tools/nov19_test.gd` PASS, smoke PASS.
- **Batch 256**: semua form hasil transfer dicek dengan overlay elips. Kyra stage2/3 (mata menyala) dan Toka stage3 alt tanpa kedip; mata kanan Tsundae evo1 digeser. Skin Angela, Mei, Rubby (pose dasar) kini berkedip (`lid_reach` 0,45–0,6); pose alternatif skin tanpa kedip; Eropatra skin tanpa kedip (mata menyala). Glytta stage1 dicek ulang setelah ganti art. flow_test: 45 rig dasar & 151 outfit bermata terukur.

## 2ww. Update 19 Nov 2026: 9 hero baru + 4 skin kostum
- **Hero baru** (`Karakter Euphoria Online/hero/New Hero 19 Nov 2026`, diimpor `tools/import_nov19.py`): Kyra (LR, DARK WARLOCK), Tora (LR, WIND ASSASSIN), Aura (UR, ICE RANGER), Sharas (UR, FIRE WARRIOR), Yumi (UR, EARTH TANK), Fuji (SSR, LIGHT HEALER), Toka (SSR, FIRE WARRIOR), Vila (SSR, DARK ASSASSIN), Tsundae (SR, FIRE MAGE). Total 46 hero. Nama file: `<n>` = stage, `evo<n>` = evolusi (`evo` tanpa angka = evo1), huruf di belakang (2a, evo1b) = ekspresi alternatif; `3a` tanpa `3` jadi base; `banner` dilewati; sprite alternatif (`1a`) tidak dipakai. Dua gambar berlatar putih (Toka 3a, Tsundae evo) dipotong ulang.
- Data: stat + skill di `DB.HEROES`, sapaan, MSG_PERSONAL/2, 5 Story Link baru (Jade Twin Flames, Sparring Partners, Field Clinic, Spotlight Rivals, Starbow & Seraph); voice JP/EN + memori + profil dari `tools/hero_content_nov19.py`, suara dibuat `tools/gen_voices.py`.
- **Skin kostum** (`Karakter Euphoria Online/Costume/Hero`): Angela "Flamingo Feather Summer", Mei "Surf Bunny Splash", Eropatra "Pumpkin Pharaoh Night", Rubby "Rubber Duck Holiday" = special skin Wardrobe (10 skin total). Art pertama = base state `special`, pose lainnya = `interactions` (dilihat di art viewer). Sprite: `special_sprite`, baru: `special_sprite_evo` dipakai di 5★ (`DB.sprite`).
- **Pivot rig + 2.5D**: 9 rig stage1 di `DB.HERO_RIGS`, 68 rig form/alt/skin di `data/char_rigs.json` (sumber `tools/rigs_dev_nov19.json`). Rig representatif diukur dari grid zoom; form berpose sama ditransfer otomatis dengan penjajaran ORB (OpenCV, similarity transform) lalu dicek dengan overlay + `tools/rig_preview.gd`. Kedipan dimatikan untuk mata bersinar/tertutup/kedip-satu-mata (Vila, Sharas, Toka evo1, Tora evo, Yumi evo) dan semua skin kostum. Depth map otomatis (`make_depth_auto.py`), import lossy 0.85 + size_limit 1200/512.
- Flow test: 46 hero, semua punya story link. PASS.

## 2vv. Update batch 254: bayangan 2.5D tanpa garis tepi, crest kartu lebih besar (17 Nov 2026)

- Bayangan jatuh di `live25d.gdshader` dan `char_rig.gdshader` adalah salinan siluet yang digeser ±2%. Di art yang terpotong di tepi gambar (±250 file, mis. Zennyo, Fidelia, Kali, Siv, Atalanta), sampel bayangan membaca di luar gambar; Godot mengulang piksel tepi sehingga bayangan jadi pita bergaris. Fungsi baru `shadow_in(p)`: bobot 0 di luar gambar dan memudar di 3% terakhir sebelum tepi. Art yang tidak menyentuh tepi tidak berubah.
- `tools/tilt_preview.gd`: env `BG=light` untuk latar terang (bayangan terlihat jelas).
- Kartu hero (permintaan user): crest rarity +40% (`clampf(w*0.21, 18, 28)`), tulisan role +20%, MAGE +40% (kata paling pendek).

## 2uu. Update batch 253: alur pemain baru lebih tenang (17 Nov 2026)

- `DB.FIRST_STEPS` 8 → 5 langkah: mail, summon, stage1, level, chapter1. Langkah bond/stage3/gear dibuang; hadiahnya pindah (bouquet ×3 ke langkah Lv.5, gems +150 dan senjata SR ke Chapter 1). Petunjuk equip gear tetap muncul lewat `_next_goal_raw`.
- Nomor STEP dihitung dari posisi langkah di daftar (`FIRST_STEPS.find`), bukan dari jumlah id tersimpan, jadi save lama yang sudah klaim bond/stage3 tetap menunjukkan angka yang benar.
- Lobby sebelum Stage 1-1 selesai: hanya tombol yang ditunjuk guide yang memakai angka merah; badge lain (Missions, Login, Notices, MENU, dll.) jadi titik oranye kecil. Setelah menang pertama badge normal lagi.
- Flow test: guide 5 langkah, hadiah bouquet/senjata, dan nomor langkah untuk save lama.
- Batch 252 (download web lebih kecil) ditunda: perlu tes di browser/HP asli.

## 2tt. Update batch 250–251: teks lebih terbaca, halaman Summon lebih jelas (17 Nov 2026)

- 250: `UI.MIN_FONT` 12 → 14 (semua `UI.label`/`wrap_label`; ukuran 9–13 di kode ikut naik). Kontras MUTED `#a79cc0` di atas panel sudah 5,9–7,4:1 (lolos WCAG 1.4.3), jadi warnanya tidak diubah. Satu-satunya yang rusak di `audit.sh`: petunjuk di dock Formation (mode bebas) mendorong tombol STORY keluar layar; teksnya dipendekkan. Audit 3 bentuk layar PASS.
- 251: panel banner hanya menampilkan rate SSR ke atas (banner Normal: semua tier) + pity/spark; paragraf aturan dipindah ke atas popup RATES sebagai poin pendek, sehingga RATES & HERO LIST dan HISTORY selalu terlihat tanpa scroll. Di popup RATES tier tanpa hero (VOID, GOD) jadi satu baris "Coming soon" di bawah.

## 2ss. Update batch 248–249: Menu hub, kartu hero, badge tenang (17 Nov 2026)

Hasil audit produk 17 Nov (temuan F7, F10, MERGE).
- 248: MENU 26 tile → 14. `DB.MENU_HUBS` (challenges: dungeon/tower/training; events: event/festival/pass; bond: messenger/date/room/kitchen/garden/expedition; collection: gallery/bestiary/photo/wardrobe). Tile hub (`lobby._hub_tile`) membuka popup kecil `_open_hub`; pin dari dalam hub membangun ulang MENU di belakangnya. Ikon Wardrobe → `item_skin_ticket`, Photo Studio → `icon_zoom`, hub Collection → `icon_ticket` (tidak ada lagi ikon dobel).
- 248: kartu hero (`hero_card._fit_badge`): crest rarity muat dalam kotak ±15%×30% lebar kartu, sejajar ikon elemen; tulisan role ±7% lebar kartu, maks 34% lebar, di ujung kanan baris Lv. Hero Detail: rarity hanya tampil sekali (crest di samping nama). Di level cap tombol LEVEL UP/+5/MAX diganti keterangan (Star Up / Limit Break / max).
- 249: `Game.feature_claim(route)` = bagian badge yang berupa hadiah. `UI.add_feature_badge`: angka merah hanya untuk hadiah, titik oranye kecil (tanpa pulse) untuk pengingat (tries, chat belum dibaca, notice, unlock baru). Badge MENU di lobby menghitung fitur yang punya hadiah.
- Flow test: bagian "[menu hubs & badges]"; tes rate-up LR diperbesar (150×10 pull) karena sebelumnya kadang gagal secara acak.
- Catatan: F11 (chip energy abu-abu) ternyata screenshot yang diambil saat chip masih fade-in, bukan bug.

## 2rr. Update batch 244–246: Gallery "Coming Soon", tap di HP (16 Nov 2026)

- 244: cek semua 37 art Lv1 dengan `tools/tilt_preview.gd` (lebar/tinggi siluet saat tilt dibanding art asli): semua ~1,00 setelah batch 237; Siv terukur lebih lebar hanya karena bayangan lantai di art-nya, figurnya tidak berubah. Kartu "?" Gallery jadi Button (ketuk → toast), form avatar terkunci tidak lagi `disabled` tapi memberi toast "Reach N★…" (HP tidak punya tooltip).
- 245: tier tanpa hero (Void, God) digabung dalam satu baris "COMING SOON" di atas Gallery; caption kartu memakai `UI.rarity_text` (VOID / GOD) bukan "???".
- 246: daftar Rates menulis "coming soon" untuk tier kosong (sebelumnya "no heroes yet").

## 2qq. Update batch 243: alat cek proporsi 2.5D (16 Nov 2026)

- `tools/tilt_preview.gd`: render art ber-rig pivot dengan tilt dipaksa (-1,0), (0,0), (1,0), (1,1) + art asli di panel kelima. Dipakai untuk memverifikasi perbaikan batch 237: Morana Lv1 dengan shader lama menyempit dan melancip ke bawah pada tilt (1,1); dengan shader baru lebar dan tinggi hampir sama dengan art asli.
- Pengukuran performa sesi ini tidak valid: Mac sedang load ~74 karena proses Chromium lain (bukan dari sesi ini), jadi angka tidak dibandingkan dengan batch 227.

## 2pp. Update batch 242: role di halaman hero sama dengan kartu (16 Nov 2026)

- Baris atas halaman hero: label teks `role_of` (WARRIOR, KNIGHT…) diganti tulisan role art (`DB.role_badge`, tinggi 17) seperti di kartu; tooltip berisi nama role asli + penjelasan.
- Chip role hanya menampilkan bagian yang belum dikatakan tulisan itu ("MAGE • AoE" → "AoE", "SUPPORT • HEALER" → "HEALER", "TANK" → tanpa chip).

## 2oo. Update batch 240–241: riwayat summon + harga "Summon Again" (16 Nov 2026)

- 240: baris Summon History memakai logo rarity (`UI.rarity_tag` 12, kolom lebar tetap 44 px) di depan nama, bukan teks "SR Vexira".
- 241: tombol "SUMMON xN AGAIN" di layar hasil menampilkan harga (`_price`), penting di banner Normal (Gold) dan saat tiket habis.

## 2nn. Update batch 238–239: sisa label rarity + kartu summon (16 Nov 2026)

- 238: Codex (`heroes.gd` `_codex_row`) memakai `UI.rarity_tag`; pelat hero di layar judul memakai `UI.rarity_text` (sebelumnya teks "LR" polos).
- 239: kartu summon tertutup untuk LR/MR/GR/OR memakai `UI.rarity_frame` (cincin animasi) sebagai tanda sebelum dibuka; SR/SSR/UR tetap halo berdenyut. Jarak baris kartu 18 → 30 px supaya "NEW!" / "+N Shards" tidak tertimpa kartu baris bawah.

## 2mm. Update batch 237: badge proporsional + 2.5D tidak menggencet (16 Nov 2026)

- Keluhan pemilik: logo rarity dan tulisan role terlalu besar / tidak proporsional; Morana terlihat gepeng oleh efek 2.5D.
- Kartu: logo rarity setinggi ikon elemen (`card_w * 0.18`, 15–26 px, di pojok kanan atas); tulisan role dipindah ke pita gelap bawah, rata kanan sejajar Lv (`card_w * 0.085`, 9–13 px, lebar maks 48% kartu). `UI.rarity_tag` 2.2 → 1.6 x ukuran. Nama VOID di `UI.rarity_text` diberi garis tepi ungu supaya terbaca.
- 2.5D: bagian "turn" di `char_rig.gdshader` dan `live25d.gdshader` tidak lagi menyempitkan gambar (`pc.x *= 1 + |yaw|…` dihapus); keystone dikali `min(aspect, 1)` dan dikecilkan (1.5 → 0.7), pitch 0.8 → 0.25. Art ramping (Morana Lv1 memakai depth otomatis) tidak lagi tergencet; parallax dan cahaya tetap.

## 2ll. Update batch: rate gacha direvisi (16 Nov 2026)

- Pemilik merevisi dokumen rarity karena hero terlalu mudah didapat: SSR 10→7%, UR 5→3%, LR 3→1%, MR 1→0,01%, GR 0,1→0,001%; OR 0,0001%, SR 20%, R 25%, N 30% tetap (`DB.RARITY_RATE`).
- Sisa persen tetap masuk ke N: Standard / rate-up N 43,99%, Normal Summon (N–SSR) SSR 7% SR 20% R 25% N 48%.
- Pity (LR+ di 80) dan jaminan 10x pertama (UR+) tidak diubah.

## 2kk. Update batch: logo rarity, tulisan role, warna nama rarity (16 Nov 2026)

- Aset dari pemilik: `rarerity image.jpg` (9 logo rarity) dan `Role Hero.jpg` (5 tulisan role) dipotong jadi PNG transparan: `art/ui/rarity/{n,r,sr,ssr,ur,lr,mr,gr,or}.png` (tinggi 192) dan `art/ui/role/{mage,fighter,tank,assassin,support}.png` (tinggi 96), dengan mipmap supaya halus saat kecil. Latar hitam dibuang: inti gambar dipertahankan penuh, cahaya di sekelilingnya jadi semi-transparan. Dua JPG sumber di root diberi `importer="skip"` supaya tidak masuk build.
- `DB.rarity_badge(r)`, `DB.role_badge(id)` + `DB.ROLE_BADGE` (TANK/KNIGHT/PALADIN → TANK, WARRIOR/RANGER → FIGHTER, ASSASSIN, MAGE/WARLOCK → MAGE, HEALER/BUFFER → SUPPORT), `UI.badge_rect(tex, h)`.
- Kartu hero: chip teks rarity diganti logo di pojok kanan atas; chip role diganti tulisan role di bawah ikon elemen.
- `UI.rarity_tag` sekarang memakai logo (tinggi sekitar 2,2 x ukuran lama), jadi Summon, Rates, Gallery, splash summon dan viewer ikut berganti.
- `UI.rarity_text(r, size)` + `game/ui/rarity_text.gdshader`: nama rarity (NORMAL, RARE, SUPER RARE, SSR, ULTRA RARE, LEGEND, MYTHIC, GOD, VOID) dengan warna border-nya; LR pelangi berjalan, MR magenta-merah, GR putih hologram berkilau, OR hitam kosmik dengan bayangan ungu. Dipakai di halaman hero (baris atas), daftar Rates dan judul Gallery. Halaman hero: logo pindah ke samping nama.
- Perbaikan: 13 latar hero baru di `backround image/new backround hero/hero_backgrounds/` ter-import lossless di build sebelumnya; sekarang lossy 0.85 (check_refs lulus).

## 2jj. Update batch: rarity baru 9 tier, 4 banner, Gallery Lv1, avatar form (16 Nov 2026)

Sumber: dokumen pemilik "Rarerity Hero 16 nov 2026.docx".

- **Rarity 9 tier** (`DB.RARITY_ORDER` N < R < SR < SSR < UR < LR < MR < GR < OR, `DB.RARITY_NAME`, `DB.RARITY_COLOR`, `DB.RARITY_RATE`, `DB.rarity_rank`, `DB.rarity_at_least`, `DB.heroes_of_rarity`). 37 hero dipindah sesuai dokumen: MR Cthollia, Micca; LR Abadonia, Tamo, Shina, Morana, Seraph, Angela, Luby; UR Valeria, Glytta, Gala, Spimei, Lucidria, Scylla, Ning Er, Mei, Kali, Kara, Xylia; SSR Hyeonxa, Schylua, Fidelia, Siv, Gemora, Rubby, Sven, Eurnipha, Eropatra, Atalanta, Zennyo Ryuo; SR Vexira, Aqua, Mora; R Furu, Lumeira; N Rumi.
- **Drop rate** persis dari dokumen (`DB.gacha_rates(tiers)`): tier tanpa hero (GR, OR) tidak ikut diundi; sisa persen (dokumen total 94,1%) masuk ke N, jadi Standard: N 36%. Opsi "topup 3jt" untuk Void belum dibuat (game masih offline, tidak ada toko uang asli).
- **Banner**: hanya 4. `nov8_morana`, `nov8_tamo` (rate-up: 50% tarikan LR jadi hero unggulan), `standard` (semua hero, wishlist SSR+), `normal` (baru: N–SSR, bayar 6.000 Gold, tanpa pity/spark/first-10x, rate SSR 10% SR 20% R 25% N 45%). Pity → LR+ di 80 (`DB.PITY_RARITY`), first 10x → UR+ (`DB.FIRST10_RARITY`), 10x tetap minimal SR.
- **Border + aura per rarity**: `game/ui/rarity_frame.gdshader` + `UI.rarity_frame(card, rarity, …)`: N–UR warna solid, LR pelangi berjalan, MR magenta-merah, GR putih hologram dengan kilau, OR hitam kosmik dengan bintang berkelip; aura makin kuat di tier tinggi. Dipakai di HeroCard dan kartu Gallery.
- **Gallery**: semua kartu memakai art utama Lv1 (`DB.art(id, 0)`, bukan portrait/evo/sprite), dikelompokkan per rarity dari OR ke N; tier tanpa hero (Void, God) tampil satu kartu "?" "Coming soon".
- **Avatar profil**: default sprite Lv1 (`DB.sprite_forms`), form lain terbuka di 4★, evo di 5★ (`DB.sprite_form_star`, `Game.sprite_form_unlocked`, `Game.avatar_form`, `UI.my_avatar`). Profil → AVATAR → baris FORM.
- Lain: filter Heroes per rarity, urutan rarity, splash/cut-in ultimate untuk SSR ke atas, shard/harga per tier (`DUPE_SHARDS`, `RECRUIT_SHARDS`, `MARKET_SHARD_PRICE`), riwayat summon menghitung semua tier.
- Catatan balance: stat dasar hero tidak diubah (masih per hero). Bintang awal ikut rarity (SSR ke atas 3★), jadi tim awal (Fidelia, Lucidria, Shina) mulai lebih kuat.
- Tes: flow test baru untuk total rate 100%, rate MR/LR, rarity hero, 4 banner, Normal Summon (Gold, N–SSR, pity tidak berubah), urutan sprite form.

## 2ii. Update batch 235 — Entrance baris yang bertahap utuh

- `UI.stagger`: item disembunyikan langsung, tween-nya dimulai satu frame setelah layar dibangun (alasan sama dengan batch 233/234; baris-baris pertama dulu muncul sekaligus). Dipakai di ±36 tempat.

## 2ih. Update batch 234 — Animasi pop popup utuh

- `UI.pop`: tween skala/pudar dimulai satu frame kemudian (isi popup dibangun setelah `pop()` di frame yang sama; tween di frame itu kehilangan sebagian besar durasinya). Berlaku untuk 14 pemakai `UI.pop`, termasuk semua `main.popup()`.

## 2ig. Update batch 233 — Transisi layar tidak melompat

- `main.go`: animasi geser/pudar layar baru dan lama dimulai satu frame setelah `build()` (`_start_transition`). Tween yang dimulai di frame build mendapat seluruh waktu build (mis. ±200 ms Heroes) sebagai langkah pertamanya, sehingga sebagian besar gerakan terjadi sekaligus.

## 2if. Update batch 232 — Frame pacing yang rata di layar 90/120/144 Hz

- Shell web mengukur refresh rate (60 frame rAF → `window.__eoHz`). `Game.display_hz()` membacanya (desktop: `DisplayServer.screen_get_refresh_rate`).
- `Game.frame_cap_for(want, hz)`: batas FPS = hz/d terlambat yang masih ≥ 95% target. 60 Hz→60, 90→90, 120→60, 144→72, 165→83; mode hemat 30: 60→30, 90→30, 144→29. Sebelumnya 60 fps di layar 90 Hz menampilkan frame berpola 1-2-1-2 refresh = tersendat walau FPS stabil.

## 2ie. Update batch 231 — Aura bernapas di belakang hero

- `UI.hero_aura(art, color, strength)`: gradasi radial aditif warna tema hero di belakang art, hanya kecerahannya yang bernapas (2,6 dtk; tidak ada gerak posisi). Dipakai di lobby dan halaman hero; dimatikan animasinya saat Reduce effects.

## 2id. Update batch 230 — Uji otomatis lebih ketat

- `tools/smoke.sh` juga gagal pada "Lambda capture … freed" dan "ERROR: Invalid" (regresi batch 227 tidak tertangkap smoke).
- `tools/audit.sh`: langkah popup BOOST memakai nama fungsi yang benar (`_power_up`); popup itu tidak ikut diaudit sejak diganti nama.
- Tur semua layar + popup: tidak ada error lain.

## 2ic. Update batch 229 — Timer milik layar/popup, avatar ulang tahun

- Regresi batch 227: pemeriksaan layout memakai `get_tree().create_timer`, sehingga bisa memanggil popup/layar yang sudah ditutup ("Lambda capture was freed"). Kini `main._owned_timer(owner, …)` dan Timer milik Screen — ikut hilang bersama pemiliknya; tween tombol ✕ dibuat di layer popup.
- Schedule: ulang tahun mendatang memakai `UI.avatar`.

## 2ib. Update batch 228 — Rune papan battle berputar halus

- `grid_board.gd::_process`: rune idle digambar ulang tiap frame (dulu tiap 3 frame ≈ 20 fps, meloncat ±1° per gambar — salah satu "gerakan kaku" di battle). Geometrinya sudah di-cache, jadi biayanya kecil.

## 2ia. Update batch 227 — Performa 60 FPS & gerakan latar yang halus

Diukur dengan langkah baru `perf:<label>` di `tools/shot_runner.gd` (90 frame: rata-rata, p95, draw call; `nocap` melepas batas FPS). Sebelum → sesudah (ms per frame, Mac ini, tanpa batas FPS): lobby avg 18,7 → 10,3, p95 25–48 → 12,6; halaman hero p95 101 → 9,8; Heroes p95 42 → 14; battle p95 71 → 13; layar judul p95 52 → 16.

- **Penyebab tersendat**: `Screen._ready` memasang Timer 0,3 dtk yang menelusuri seluruh layar (auto-fit) selama layar terbuka; popup punya timer 0,25 dtk + 0,05 dtk. Kini hanya 3 kali saat layar/popup dibuka (0,12/0,5/1,2 dtk) + saat resize; tombol ✕ hanya mengikuti panel selama animasi pop.
- **Shader rig** (`char_rig.gdshader`): loop tulang/floats/glows berhenti di jumlah slot yang dipakai (`bone_count`, `float_count`, `glow_count`) — gambar identik.
- **Web**: rasio piksel kanvas dibatasi 2 (`web_landscape_patch.py`, `getPixelRatio`). Ponsel DPR 3 sebelumnya merender 2,25× lebih banyak piksel.
- **Gerakan latar dihapus, diganti efek** (permintaan user: gerakan terasa kaku/seperti lag): battle — zoom/geser latar diganti `UI.light_shafts` + cahaya bernapas (`self_modulate`), sinar matahari berdenyut alih-alih berputar; lobby — parallax latar/hero dan goyangan idle (batch 199) dihapus; halaman hero — latar tidak lagi bergeser.
- **Layar loading web**: hanya gambar (nama/gelar/kutipan hero dihapus), tombol emas besar diganti tulisan kecil berkedip "ketuk untuk masuk".

## 2hz. Update batch 225 — Bestiary menunjuk chapter yang tepat

- `DB.chapters_with(id)`: chapter yang pool atau bosnya memuat musuh itu. "WHERE TO FIND HER" menampilkan chapter pertama (+ jumlah lainnya); GO membuka Story tepat di stage pertama chapter tersebut. Baris lokasi memakai `wrap_label` (versi pertama membuat panel lebih lebar dari layar — tertangkap `tools/audit.sh`).

## 2hy. Update batch 224 — Bestiary: yang ditemukan di atas

- `bestiary.gd::_ordered()`: musuh yang sudah dikalahkan duluan (urut jumlah kill), sisanya urutan biasa; layar membuka musuh pertama yang ditemukan. Dengan 33 musuh, temuan pemain dulu tersebar di antara siluet.

## 2hx. Update batch 223 — Pemberitahuan musuh baru ditemukan

- `Game.record_kills`: kill pertama sebuah musuh memunculkan toast "NEW FOE DISCOVERED: …" (beberapa musuh dalam satu battle digabung dalam satu toast lewat pengelompokan toast yang sudah ada).

## 2hw. Update batch 222 — Tiga World Boss baru

- `DB.WORLD_BOSSES` 8 → 11: Lolth (necro), Code Zero (space), Octavia-Vex (aqua). Urutan dipilih supaya minggu pembaruan (week 2967 → indeks 8) tetap Serpentia; progres mingguan pemain tidak berpindah boss.

## 2hv. Update batch 221 — Kartu musuh juga di Battle Prep

- `_foe_info` dipindah ke `main.foe_info(e)` dan dipakai di Story maupun `formation.gd::_layout_enemies` (unit musuh di papan kini bisa diketuk; ukuran area sentuh diset manual).

## 2hu. Update batch 220 — Info musuh dari panel stage Story

- `story.gd::_foe_info`: wajah musuh di panel stage bisa diketuk → popup avatar, nama (varian/BOSS), gelar, elemen, peran, level, skill + deskripsi, dan elemen yang efektif melawannya.
- `shot_runner.gd`: argumen `cur:` boleh berupa JSON (`;` sebagai koma).

## 2ht. Update batch 219 — Deskripsi skill musuh

- `DB.skill_desc(sk)` menulis deskripsi dari data skill (area, sasaran, % ATK, burn/stun/silence/DEF down/heal block/drain/execute/crit/shield/taunt). `DB.skill_of(id)` untuk musuh mengembalikan salinan ber-`desc` (cache `_enemy_skill`; tabel const tidak diubah).
- Tampil di info unit saat musuh diketuk dalam battle dan di halaman Bestiary (yang kini memakai `DB.skill_of`).

## 2hs. Update batch 218 — 13 realm hero baru, penjaga ukuran impor

- File background hero baru dari user (abadonia, eropatra, furu, glytta, hyeonxa, luby, micca, ninger, rubby, schylua, seraph, siv, spimei) otomatis terbaca `DB.hero_bg_key`; impornya disetel lossy 0,85 tanpa mipmap (tadinya lossless). Total 27 hero + 1 skin khusus punya realm.
- Banner event Octra & Hyeonxa juga diimpor lossy.
- `tools/check_refs.py` kini gagal bila ada art karakter, background atau banner yang diimpor lossless.

## 2hr. Update batch 217 — Build web kembali ±136 MB

- 210 file `.import` di `art/characters/` masih lossless (`compress/mode=0`, `size_limit=0`): semua musuh 15 Nov, Octra, serta hero gala, hyeonxa, morana, seraph, tamo. Disamakan dengan standar proyek: lossy 0,85, `size_limit` 1200 (art) / 512 (sprite). PCK 235 MB → 136 MB. Koordinat rig berbasis UV, jadi tidak terpengaruh.
- Setelah impor art baru: periksa `grep -rl "^compress/mode=0" art/characters --include=*.import` harus kosong.

## 2hp. Update batch 215 — Sumber Skill Book & helper `_source_row`

- `hero_detail.gd::_source_row(parent, title, item, list)`: baris tombol GO dari daftar eksplisit atau `DB.item_sources(item)` (maks. 3, fitur terkunci/lobby dilewati). Dipakai untuk shard (Star Up) dan Skill Book (Skill Up yang terkunci). Baris memakai `HFlowContainer` agar tombol membungkus ke baris kedua di layar sempit (versi pertama membuat panel lebih lebar dari layar — tertangkap `tools/audit.sh`).

## 2ho. Update batch 214 — Tombol sumber shard di Star Up

- `hero_detail.gd`: bila shard kurang, baris "GET SHARDS:" dengan SUMMON ▶ / BLACK MARKET ▶ / BOSS HUNT ▶ (Boss Hunt hanya bila sudah terbuka) menggantikan kalimat petunjuk.

## 2hn. Update batch 213 — Tautan "GET EXP / GOLD" di tab Upgrade

- `hero_detail.gd`: bila EXP atau Gold kurang untuk level berikutnya (dan Dungeon sudah terbuka), tombol kecil di baris biaya membuka Daily Dungeon pada Crystal Sanctum / Golden Vault.

## 2hm. Update batch 212 — Perkiraan sisa waktu unduhan

- Shell web: `eta()` menghitung kecepatan unduh (dihaluskan, diperbarui tiap ≥ 1,5 dtk) dan menambahkan "±N dtk/mnt lagi" ke teks progres.

## 2hl. Update batch 211 — UPGRADE setelah kalah menuju hero terlemah

- `battle.gd::_show_result`: tombol UPGRADE pada kekalahan membuka `hero_detail` hero dengan power terendah di formasi (tab UPGRADE, swipe di antara anggota tim); tooltip menyebut namanya.
- `hero_detail.gd`: untuk LIGHT/DARK (saling mengalahkan) satu chip "RIVAL ⇄" menggantikan STRONG VS + WEAK TO yang tampak bertentangan.

## 2hk. Update batch 210 — Kartu hasil summon bisa diketuk

- `gacha.gd::_play_reveal`: setelah semua kartu terbuka (`_reveal` meta `done`), tiap kartu membuka `ArtViewer` hero itu; petunjuk "Tap a card to view her art" di atas tombol.

## 2hj. Update batch 209 — Toast penolakan bergoyang

- `main.toast`: toast merah bergoyang singkat (rotasi, 5 langkah × 0,05 dtk) setelah muncul; selain itu suara `ui/error` + getar dari batch sebelumnya.

## 2hi. Update batch 208 — Titik merah di tab hero

- `Game.bond_stories_new_for(id)`; `hero_detail.gd`: titik merah di pojok kanan atas tab UPGRADE (Star Up siap) dan BOND (memori belum dibaca).

## 2hh. Update batch 207 — Avatar di pemilih Heart Catch

- `minigame.gd`: baris PLAY AS memakai `UI.avatar` (56 px, bingkai merah muda untuk pilihan aktif) menggantikan potongan wajah bulat.

## 2hg. Update batch 205 — Peringatan slot kosong di Battle Prep

- `formation.gd::_start`: bila jumlah hero di tim < min(5, hero yang dimiliki) (kecuali Trial), popup "EMPTY SLOTS" dengan AUTO FILL (`Game.auto_formation` dengan elemen counter dari scout) atau FIGHT ANYWAY (`static var _gap_ok`, tidak ditanya lagi selama sesi). Logika bayar/mulai dipindah ke `_launch()`.
- `shot_runner.gd`: langkah `gpop:<key>` untuk menguji.

## 2hf. Update batch 204 — Pakai Energy Flask langsung dari Story

- `story.gd::_offer_flask`: bila Energy kurang dan pemain punya Energy Flask, muncul popup "OUT OF ENERGY" dengan USE FLASK & FIGHT (memakai `Game.use_item`, lalu langsung ke battle) atau NOT NOW. Tanpa flask tetap toast seperti dulu.

## 2he. Update batch 203 — Pembelian di Shop terasa

- `main.fly_from(textures, from)`: ikon melengkung dari titik ketuk ke bar mata uang (dipakai ulang dari animasi hadiah).
- `shop.gd`: setelah membeli, ikon barang terbang + suara `ui/reward`.

## 2hd. Update batch 202 — Tombol ✕ di setiap popup

- `main.popup()`: popup yang bisa ditutup mendapat tombol bulat ✕ (40 px) di pojok kanan atas, mengikuti posisi, skala dan alpha panel (termasuk animasi pop), dijaga tetap di dalam layar.

## 2hc. Update batch 201 — Tanda Star Up siap di kartu hero

- `Game.star_up_ready(id)` (hanya membaca: shard + Star Stone universal + Gold cukup, belum bintang maks.).
- `HeroCard` opsi `star_ready`: pil hijau "▲★" berdenyut di kanan kartu; dipakai di daftar Heroes.

## 2hb. Update batch 200 — AUTO dialog diingat

- `vn_dialogue.gd`: `static var _auto_pref`; adegan berikutnya (non-tutorial) mulai dengan AUTO aktif bila terakhir dinyalakan.

## 2ha. Update batch 199 — Parallax lobby di ponsel

- `lobby.gd`: parallax hero/background hanya bereaksi pada gerak mouse, jadi di layar sentuh diam. Setelah 2,5 dtk tanpa gerak pointer, `_parallax` mengikuti angka delapan lambat (dimatikan oleh Reduce effects).

## 2gz. Update batch 198 — Kartu judul chapter bisa diketuk

- `story.gd::_chapter_card`: lapisan kartu menangkap ketukan dan memudar dalam 0,18 dtk (sebelumnya ±3 dtk menutupi panel stage dan tombol BATTLE).

## 2gy. Update batch 197 — Kenaikan stat terlihat saat upgrade

- `hero_detail.gd::_stat_gain(before)`: setelah Level Up / Star Up, selisih HP / ATK / DEF (warna masing-masing) naik di bawah teks besar lalu memudar.

## 2gx. Update batch 195 — Avatar seragam di Arena & Guild

- `arena.gd`: baris peringkat (#4 dst.) dan log pertahanan memakai `UI.avatar`; baris "(You)" memakai `Game.avatar_id()` dengan bingkai hijau.
- `guild.gd`: daftar anggota memakai `UI.avatar`.

## 2gw. Update batch 194 — Daftar penghuni Garden

- `garden.gd::_render_hud`: potongan wajah diganti `UI.avatar` (sprite full body, bingkai warna tema hero); hati terpakai merah muda penuh, sisa berupa garis tipis (dulu semuanya satu warna).

## 2gv. Update batch 193 — Daftar Boss Hunt terbaca

- `hunt.gd`: gradasi gelap dari kiri di tiap kartu target (di bawah nama, status dan hadiah).

## 2gu. Update batch 192 — Bag & Missions mengingat tab

- `bag.gd` (`_tab`, `_filter`) dan `quests.gd` (`_tab`, `_ach_cat`) kini `static var`; parameter `tab` dari luar tetap menang.

## 2gt. Update batch 191 — Daftar Heroes mengingat filter dan posisi

- `heroes.gd`: `_filter`, `_elem`, `_role`, `_sort` dan posisi scroll jadi `static var` (bertahan selama sesi). Kembali dari detail hero tidak lagi mereset daftar ke ALL / Power / atas.

## 2gs. Update batch 190 — Sel Season Pass & petunjuk Expedition

- `pass.gd::_cell`: hadiah berdampingan (ikon + jumlah per hadiah) alih-alih bertumpuk; sel Premium terkunci memakai tanda kecil di pojok, baris status hanya untuk CLAIM! / ✔ CLAIMED.
- `expedition.gd`: petunjuk dipendekkan jadi dua baris (yang lama membungkus tiga baris dan keluar di atas bar ringkasan).

## 2gr. Update batch 189 — Label papan Battle Prep tidak tertutup unit

- `formation.gd::_side_tag`: label "YOUR TEAM • FRONT LINE ▶" dan "◀ ENEMY FRONT LINE" kini di atas pil gelap dengan `z_index` 20; sebelumnya sprite tinggi di baris belakang menutupinya.

## 2gq. Update batch 188 — Ukuran ikon seragam

- `tools/fit_icons.py`: ikon yang gambarnya hanya memakai < 80% kanvas di-crop dan diskalakan ke 94%; asli disimpan di `_recut_backup/icons_small/`. Terkena: `icon_festival` (50%) dan `item_season_token` (49%), keduanya 256 px sehingga tetap tajam.
- Lembar kontak 81 ikon diperiksa; ikon lain sudah konsisten.

## 2gp. Update batch 187 — Layar kemenangan, ikon Equipment & Gear Chest

Batch perbaikan (tanpa fitur baru).

- `battle.gd::_show_result`: tiga syarat bintang jadi chip (★ hijau bila terpenuhi, ☆ merah redup bila tidak) yang muncul berurutan; hadiah 44 px muncul satu per satu dengan pop + suara `ui/tab` (dilewati saat Reduce effects).
- `art/icons/icon_equipment.png` digambar ulang (pedang + perisai; yang lama tampak seperti kotak dicoret, cadangan di `_recut_backup/icon_equipment_old.png`).
- Gear Chest memakai ikon peti baru `item_gear_chest.png` (Royal Chest diwarnai baja-perunggu).

## 2gl. Update batch 186 — Pemeriksaan akhir dan publish

- `tools/flow_test.gd` PASS, `tools/smoke.sh` PASS, `tools/audit.sh` PASS di 1280×720, kanvas sempit (1,23) dan 1560×720 X-LARGE, `tools/check_refs.py` bersih (81 ikon, 373 suara, 27 background).
- Build web di-publish dengan slideshow loading baru (8 hero di realm masing-masing) dan font simbol.
- Catatan untuk aset berikutnya: background hero baru cukup ditaruh sebagai `bg_<id hero>.jpg` di folder `new backround hero/hero_backgrounds/`, lalu impor (lossy 0,85, tanpa mipmap) dan jalankan `tools/make_loading_art.py` bila hero itu ada di slideshow.

## 2gk. Update batch 185 — Perbaikan regresi auto-fit, realm di Art Viewer & Messenger

Batch perbaikan (tanpa fitur baru).

- **Regresi batch 167 diperbaiki**: `UI.fit_tall` membungkus panel yang sudah punya daftar scroll sendiri, karena label wrap melaporkan tinggi sangat besar sebelum layout pertama. Akibatnya daftar chat Messenger menciut jadi nol. Sekarang panel dengan `ScrollContainer` ber-expand dilewati, pemeriksaan pertama ditunda sampai layout selesai (0,12 dtk layar, 0,08 dtk popup), dan panel selebar < 80 px diabaikan.
- Audit layout: jenis baru **`FLAT`** (area scroll berisi tapi tingginya < 8 px) — ikut menggagalkan `tools/audit.sh`.
- `art_viewer.gd`: latar = realm hero (lebih terang) bila ada. `messenger.gd`: latar mengikuti lawan chat.

## 2gj. Update batch 184 — Punggung kartu summon baru

Batch perbaikan tampilan (tanpa fitur baru).

- `tools/gen_card_back.py` menggambar `art/ui/card_back.png` (300×390): bidang ungu dengan kisi berlian, tiga bingkai emas, berlian sudut, medali bulan sabit + bintang. `gen_ui_kit.py` tidak lagi menimpa file itu.

## 2gi. Update batch 183 — Percikan sentuh dan getaran

Batch perbaikan interaksi (tanpa fitur baru).

- `game/ui/tap_fx.gd` + `main._input`: cincin kecil dan 6 percikan di titik sentuh (kosmetik, tidak memakan input, maks. 7 sekaligus).
- `Game.haptic(ms)`: `Input.vibrate_handheld` di mobile / web Android untuk crit (22 ms), ledakan summon (30/60/120 ms menurut rarity), reward (18 ms), toast error (28 ms). Tidak aktif di desktop dan saat Reduce effects.

## 2gh. Update batch 182 — Realm hero di belakang ultimate

Batch perbaikan animasi (tanpa fitur baru).

- `battle.gd::_ultimate`: lapisan realm hero (tint elemen, alpha 0,42, zoom lambat) di antara langit gradien dan garis kecepatan. Hanya untuk hero yang punya background sendiri.
- `DB.warm_battle_art` ikut memuat realm itu saat battle dibuka, supaya ultimate pertama tidak tersendat.

## 2gg. Update batch 181 — Layar judul di realm hero

Batch perbaikan (tanpa fitur baru).

- `title.gd`: background = realm hero yang tampil (bila ada), ditambah `UI.light_shafts()` berwarna tema hero.
- `UI.light_shafts(tint, strength, origin)`: pembungkus shader cahaya volumetrik agar bisa dipakai layar lain.

## 2gf. Update batch 180 — Set suara UI

Batch perbaikan interaksi (tanpa fitur baru).

- `tools/gen_ui_audio.py` mensintesis 6 suara pendek ke `audio/ui/`: `open`, `close`, `tab`, `error`, `reward`, `confirm` (mono 44,1 kHz, lembut).
- Dipasang di: `main.popup()` (open), `_dismiss` (close), `UI.button` varian TabButton (tab), `main.toast` warna merah (error), `main.show_rewards` (reward).
- `Game.sfx`: suara `ui/…` yang sama tidak menumpuk dalam 140 ms.

## 2ge. Update batch 179 — AUTO formation yang memperhatikan komposisi

Batch perbaikan gameplay (tanpa fitur baru).

- `Game.auto_formation`: setelah memilih 5 hero terkuat, bila tidak ada TANK/PALADIN/KNIGHT atau tidak ada HEALER/BUFFER, hero dengan peran itu menggantikan pilihan terlemah asalkan skornya ≥ 60% (front-liner) / 55% (support) dari yang digantikan. Satu-satunya tank/support tidak pernah jadi korban tukar.
- Flow test: roster 5 DPS + healer + tank yang sedikit lebih lemah → keduanya masuk; bila jauh lebih lemah → tidak.

## 2gd. Update batch 178 — Kartu gacha diantar jejak cahaya

Batch perbaikan (tanpa fitur baru).

- `gacha.gd::_comet`: tiap kartu diantar garis cahaya melengkung dari gerbang (warna rarity), dengan kilatan saat mendarat; kartu muncul dari titik jatuhnya. Dilewati bila di-skip atau Reduce effects aktif.
- Jeda 0,28 dtk setelah ledakan agar cincin kejut terlihat sebelum kartu tampil.

## 2gc. Update batch 177 — Realm tiap hero, 2.5D lebih dalam, info elemen di layar hero

Batch perbaikan (tanpa fitur baru). Termasuk pekerjaan pra-batch atas permintaan user.

- **Font simbol** (`art/fonts/symbols_dejavu_bold.ttf`, `Game._install_symbol_font`): font bawaan tidak punya ★ ♥ ✦ ▶ ✓ ⚔ dll. (42 simbol); di web tampil sebagai kotak berisi kode ("kotak-kotak" di bawah nama hero = baris bintang). Subset DejaVu Sans Bold 42 KB jadi fallback; 9 emoji diganti. Tes: `NOSYSFONT=1`.
- **Background hero** (`DB.hero_bg_key`, `bg("hero:<id>")`): file `bg_<id>.jpg` di `backround image/new backround hero/hero_backgrounds/` terbaca otomatis (15 hero; lainnya pakai map elemen). Dipakai di layar hero, memori & talk, banner rate-up, splash SSR, Photo Studio, scene lobby "Her Realm", slideshow loading.
- **2.5D** (`live25d.gdshader`): putaran pseudo-3D, parallax 6 langkah, cahaya kunci dari normal depth, kilau, cahaya tepi, bayangan jatuh; `LiveRig.backdrop` menggeser background berlawanan arah.
- **Lobby**: area sentuh hero tanpa kotak gelap; cahaya volumetrik (`light_shafts.gdshader`) menggantikan 4 batang miring.
- **Battle**: cut-in ultimate di-frame pada wajah (`DB.face_focus`).
- **Avatar** (`UI.avatar`): sprite full body seragam di lobby, profil, pemilih avatar, Friends, Settings.
- **Gacha**: gerbang summon baru (`SummonFX`, `summon_core.gdshader`).
- Layar hero: chip STRONG VS / WEAK TO di bawah bintang, cuaca elemen (`FestivalFX`).
- Sprite Eurnipha ★5: pola kotak transparan yang ikut tergambar dihapus.

## 2gb. Update batch 176 — Halaman web: layar loading baru, kartu pratinjau, safe area

Batch perbaikan (tanpa fitur baru).

- **Layar loading web ditulis ulang** (`web_shell/euphoria_shell.html`): progress bar dulu ikut aturan `position:absolute; left:0` milik overlay sehingga menempel ke kiri dan menumpuk teks. Sekarang panel terpusat yang menskala dengan tinggi layar (`clamp()` + `vh`), layout portrait tersendiri, dan slideshow 8 hero di depan map in-game (ganti tiap 7 dtk atau ketuk), 16 tip bergilir.
- `tools/make_loading_art.py` membuat gambar kecil ke `web_shell/loading/` (±2,5 MB, dimuat satu per satu); `publish_web.sh` menyalinnya ke `web/loading`.
- **Meta halaman**: description, Open Graph (`og:title/description/image`), `twitter:card`, preload logo. Kartu pratinjau 1200×630 `loading/share.jpg`. Catatan: `og:image` masih path relatif — ganti ke URL absolut bila domain sudah tetap (WhatsApp/Facebook memintanya).
- **Safe area** (`viewport-fit=cover`): logo, caption dan panel loading memakai `env(safe-area-inset-*)`.

## 2ga. Update batch 175 — Naskah Arc 13: Scylla sesuai art-nya

Batch perbaikan (tanpa fitur baru).

- Ch.52 `boss_lines` (Gala): "you have EIGHT arms" → lelucon tentang seratus topeng tanpa gaun yang serasi.
- Interlude i13 (Scylla): "A child asked to ride on a tentacle" → anak itu minta memegang sabitnya, lalu tangannya. Art Scylla tidak punya tentakel; yang bertentakel adalah Cthollia (barisnya tidak diubah).
- Sapuan proofreading otomatis atas semua string di `db.gd`, `news.json`, `memories.json`, `voice_lines.json`, `profiles.json` (kata berulang, spasi sebelum tanda baca, koma tanpa spasi, salah eja umum, "a" + vokal): tidak ada temuan nyata.

## 2fz. Update batch 174 — Panduan pertama untuk mode lama yang terlewat

Batch perbaikan (tanpa fitur baru). Ditemukan lewat sapuan konsistensi data (hero, item, musuh, fitur).

- Enam fitur di `DB.FEATURE_UNLOCK` tidak punya entri `DB.TUTORIALS`: **tower, event, friends, pass, bestiary, gallery**. Ditambahkan (2 baris, masing-masing oleh satu hero) + pemanggilan `tutorial("…")` di tiap layar. Otomatis masuk Guide Archive (kini 28 panduan). Pemain lama melihatnya sekali saat membuka mode itu lagi.
- `ITEM_SOURCES`: Sweet Cake, Moonlight Perfume dan Rune Pouch mencantumkan sumber selain toko (Festival Exchange, Weekly Missions, Achievements).
- Sapuan yang sama tidak menemukan hero tanpa profil / memori / voice / face / sprite, item tanpa deskripsi, atau musuh tanpa art.
- Flow test: tiap fitur yang bisa dibuka (kecuali mini-game, yang punya kartu intro sendiri) wajib punya panduan.

## 2fy. Update batch 173 — Target sentuh yang lebih besar

Batch perbaikan (tanpa fitur baru).

- Audit layout punya jenis **`TINY`**: teks di bawah 11 px atau tombol aktif yang sisi terpendeknya < 30 px. Dari 85 layar/popup hanya dua pola yang muncul.
- **Chip Gems / Energy** (`Screen._chip`): seluruh chip kini bisa ditekan untuk membuka Shop; dulu hanya "+" selebar 26 px.
- **Pil lobby** (TALK, OUTFIT, SCENE, FORTUNE, VIEW, HERO): tinggi 28 → 36 px, teks 11 → 13 px, opasitas 0,85 → 0,92.

## 2fx. Update batch 172 — Referensi aset yang gagal diam-diam, nama hero terbaca

Batch perbaikan (tanpa fitur baru).

- **`tools/check_refs.py`**: memindai semua `icon("…")`, `"icon_/item_/elem_…"`, `sfx("…")`, kunci `bg` di kode dan `data/news.json` terhadap file yang ada. Ikon hilang hanya jadi kotak kosong dan suara hilang hanya senyap, jadi tidak pernah terlapor.
- Temuan: `Game.sfx("buff")` di Kitchen (file ada di `audio/battle/`) → kini `battle/buff`; notice `n2026-11-08p` (bg `hunt`) dan `n2026-11-08m` (bg `worldboss`) memakai kunci yang tidak ada → `space` / `hell`.
- **Hero detail**: bayangan radial lembut di belakang blok nama (tag rarity/elemen/kelas, nama, gelar) yang menumpang di atas art.
- Flow test: tiap notice harus memakai background yang ada.

## 2fw. Update batch 171 — Audit layout permanen, tes yang stabil, petunjuk putar ponsel

Batch perbaikan (tanpa fitur baru).

- **`tools/audit.sh`** (`zsh tools/audit.sh`, atau `quick`): membuka 45 layar + 40 popup pada tiga bentuk kanvas — 1280×720 default, 1280×720 kanvas sempit (skala 1,23), 1560×720 X-LARGE — dan gagal bila ada `CLIP` / `CUT` / `OFF`. Jalankan sebelum rilis bersama `tools/smoke.sh`. Hasil sekarang: PASS di ketiganya.
- **Tes "Crimson Thirst lifesteal"** tidak lagi acak: gear tes punya substat acak sehingga satu battle kadang selesai tanpa event heal (~1 dari 12 run gagal palsu). Sekarang lifesteal cukup muncul di salah satu dari 8 seed.
- **Shell web**: layar "Putar ponselmu" saat game dipegang tegak di layar sentuh (`#rotate-hint`, hanya setelah loading selesai — `body.game-on`). Dulu game tampil sangat kecil dan memanjang.
- Slideshow loading: timer pergantian slide tidak lagi menyentuh elemen yang sudah dihapus saat game mulai (TypeError).
- `shot_runner.gd`: `TIMING=1` mencetak waktu buka tiap layar.

## 2fv. Update batch 170 — Keterbacaan: Training Ground, Festival, World Boss, Date

Batch perbaikan (tanpa fitur baru).

- **Training Ground**: grid 3×2 yang mengisi seluruh area (dulu 3+2 kartu dengan lubang dan sisa kosong di bawah). Tiap mode (DUMMY / SPARRING) jadi strip sendiri; ubin keenam "YOUR RECORDS" menampilkan rekor tertinggi dari data yang sudah ada + jumlah run.
- **`UI.scrim(from_top, height, alpha)`**: gradasi gelap untuk teks di atas artwork.
- **Festival**: scrim di belakang judul dan teks aturan (dulu tertimpa art hero). **World Boss**: scrim atas & bawah. **Date**: scrim di bawah nama Date Spot.

## 2fu. Update batch 169 — Popup yang selalu muat di layar

Batch perbaikan (tanpa fitur baru). Ditemukan lewat audit layout pada 40+ popup.

- **`UI.fit_tall(panel, head, max_h)`**: logika auto-fit dipindah ke `UI` dan dipakai juga oleh `main.popup()`. Popup yang lebih tinggi dari layar mendapat area scroll; judul dan sampai dua baris tombol di bawah tetap diam. Dicek ulang tiap 0,25 dtk selama popup terbuka (isi bisa berubah).
- Yang tadinya rusak: **NOTICES** (panel 7.749 px — daftar notice tanpa scroll), **INTERLUDES** (896 px), **LOBBY SCENE** (1.101 px), **RATES** (1.000 px, tombol CLOSE di bawah layar).
- Notices: daftar di kiri punya scroll sendiri dan otomatis menggulir ke notice yang dipilih.
- Interludes diurutkan menurut syarat stage (urutan buka).
- Battle Prep: tag "▲ +30%" tidak lagi menutupi tag kelas di kartu hero.
- Layar judul: papan nama hero dianimasikan lewat offset anchor (dulu posisi basi → bisa setengah keluar layar bila jendela berubah ukuran saat intro).
- Audit `OVER` hanya memeriksa popup teratas bila ada popup terbuka.

## 2ft. Update batch 168 — UI X-LARGE yang benar-benar muat

Batch perbaikan (tanpa fitur baru).

- **`Game.effective_ui_scale()` + `UI_MIN_WIDTH` 1040**: skala UI dibatasi agar lebar kanvas tidak pernah di bawah lebar desain. Di 16:9 X-LARGE dulu membuat kanvas 985 px sehingga BATTLE (Story), SUMMON x10, baris tab hero detail, kartu Arena/Dungeon/Event keluar dari tepi kanan. Sekarang 16:9 → 1,23; ponsel lebar (19,5:9) tetap 1,3. Mengikuti resize jendela/rotasi (`root.size_changed`).
- **Header adaptif** (`Screen._fit_header/_hdr_apply`): bila baris header lebih lebar dari layar, ikon disembunyikan → chip dirampingkan → judul diperkecil → judul dipotong "…". Kembali normal saat layar melebar.
- Story: SWEEP x1 / x5 / TEAM (font 14) muat di panel sempit. Arena: kolom nama fleksibel, wajah tim 36 px, tombol BATTLE 108. Summon: tombol pull 216. Wardrobe: nama + gelar membungkus. Private Room: lima ruangan berbagi tinggi kolom. Garden: nama hero tidak lagi turun di bawah layar.
- Alat audit menampilkan anak dengan lebar minimum terbesar (`AUDIT widest`) untuk panel yang terlalu lebar.
- Hasil audit: 0 temuan di 1280×720 (LARGE), 1280×720 skala 1,23, dan 1560×720 X-LARGE.

## 2fs. Update batch 167 — Perapian layout: audit otomatis, auto-fit panel, Heroes & Tower

Batch perbaikan (tanpa fitur baru).

- **Alat audit layout** di `tools/shot_runner.gd` (`AUDIT=1`): tiap layar dilaporkan `CLIP` (teks terpotong tanpa elipsis), `TRIM` (elipsis yang membuang >40% teks), `CUT` (keluar dari parent yang meng-clip), `OFF` (teks/panel keluar jendela) dan `OVER` (dua teks bertumpuk).
- **Auto-fit panel** (`Screen._fit_scan/_fit_panel`): panel yang isinya lebih tinggi dari layar dibungkus scroll, baris tombol aksi di bawah tetap menempel. Sebelumnya di UI X-LARGE tombol seperti CHALLENGE (Tower) atau baris terakhir Bag/Mail jatuh di bawah layar.
- **`UI.fade_in`**: untuk node di dalam Container, posisi akhir dulu dibaca sebelum layout (0,0) sehingga isi panel menempel ke bingkai (Tower, panel info Summon, Oath). Sekarang digeser relatif ke posisi dari container.
- **Heroes**: kartu awal 170 px memaksa kolom 21 px melewati tepi kanan; ukuran kartu kini mengikuti lebar layar. Jumlah hero + bonus koleksi jadi dua baris pendek, badge CODEX tidak menutupi huruf.
- **Tower**: banner 84 px, tombol 54 px — panel pas tanpa scroll di ukuran default.
- 23 label `clip_text` sekarang berakhir dengan "…".

## 2fr. Update batch 166 — Filter kelas di layar Heroes

- `DB.ROLE_GROUPS` / `ROLE_GROUP` / `role_group(id)`: 10 role dikelompokkan jadi TANK (Tank, Knight, Paladin), DPS (Warrior, Assassin, Ranger), MAGE (Mage, Warlock), SUPPORT (Healer, Buffer).
- `heroes.gd`: tombol ANY / TANK / DPS / MAGE / SUPPORT di kanan baris filter elemen (`_role`), digabung dengan filter rarity, elemen dan sort. Pesan "No heroes match these filters." bila hasil kosong.

## 2fq. Update batch 165 — Guide Archive

- `settings.gd::_show_guides`: popup daftar semua `DB.TUTORIALS` (2 kolom, urut nama), tap untuk memutar ulang lewat `main.dialogue(..., compact)` lalu kembali ke daftar. Tutorial yang belum pernah muncul (`tips_seen`) diberi tanda NEW; memutar dari arsip tidak menandainya sebagai sudah dilihat, jadi tetap muncul saat mode dibuka pertama kali.
- `DB.tutorial_name(key)` / `tutorial_icon(key)`: nama dan ikon dari `MENU_FEATURES`, dengan pengecualian di `TUTORIAL_NAMES`.

## 2fp. Update batch 164 — FUSE ALL untuk rune

- `Game.fuse_all_plan()`: simulasi per tipe rune dari tier 1 ke atas; hasil fusi ikut dihitung untuk tier berikutnya, dibatasi Gold. Hasil `{steps: [[type, tier, times]], fusions, gold}` tanpa mengubah save.
- `Game.fuse_all_runes()`: menjalankan rencana itu lewat `fuse_runes()`; `made` berisi rune hasil akhir. Rune yang sedang dipakai hero tidak disentuh (`fusable` hanya rune bebas).
- `bag.gd` tab RUNES: tombol **FUSE ALL RUNES (n)** di panel detail, dengan konfirmasi jumlah fusi dan biaya Gold.

## 2fo. Update batch 163 — Arc 13: The Jade Masquerade

- **4 chapter baru (49–52, total 52 chapter / 312 stage)**: The Thousand-Coin Ball (bos Masked Ning Er), The Endless Duel (Mei), The Hall of Verdicts (Angela), Maskmaker's Grotto (Scylla). Struktur sama dengan arc sebelumnya (intro, mid, mid2, boss_lines, outro, pilihan VN, field mod).
- **Varian baru `jade`** (prefix `jade:`, nama "Masked X"): `UI.corrupt` (desat 0,6, tone 0,78/1,36/0,98, halo hijau pucat), `DB.base_id` / `name_of` / `theme_color`, `vn_dialogue.gd`, label MASKED + modulate hijau di `battle.gd`, `DB.RIFT_VARIANTS`.
- Penutup Arc 12 jadi pengantar Arc 13. Interlude `i13` "The Unmasked Ball" (req 312), title `unmasked`, achievement `ch52`, Story Link `faces` (Scylla + Angela + Mei), mail `arc13_jade`.
- `story.gd`: tab ARC 13 (chapter 48+). Flow test diperluas ke chapter 45–52.

## 2fn. Update batch 162 — Shortcut yang di-pin di MENU

- `Game.pins()` / `toggle_pin(route)` (maksimal `PIN_MAX` = 6, disimpan di `s["pins"]`, route yang sudah tidak ada dibuang).
- `lobby.gd::_open_menu`: bagian **★ PINNED** paling atas (petunjuk singkat bila kosong). `_menu_tile`: tombol ☆/★ kecil di pojok kiri atas tiap tile untuk pin/unpin; badge tetap tampil di tile yang di-pin.

## 2fm. Update batch 161 — Backup otomatis save

- `Game.make_backup(tag)`: menulis `s` ke `user://backups/save_<tag>.json`. Tag kosong = backup harian (`day_key`), dibuat di `load_game()` bila belum ada untuk hari itu (isi = save saat game dibuka). Hanya `BACKUP_KEEP` (5) backup harian terbaru yang disimpan; tag `before_restore` dan `before_reset` di luar batas itu.
- `Game.backups()`: daftar backup yang bisa dibaca (label tanggal, level, jumlah hero, stage). `Game.restore_backup(path)`: menyimpan progres sekarang sebagai "Before Restore", lalu memuat backup lewat jalur `_merge` + `_sanitize` yang sama dengan Backup Code.
- **Save rusak**: sebelumnya file save yang gagal di-parse membuat game mulai dari nol dan menimpa file itu. Sekarang file rusak disalin ke `save_damaged.json`, backup terbaru dimuat, dan pemain diberi toast (`Game.restored_from`).
- `reset_save()` membuat backup `before_reset` dulu.
- `settings.gd`: tombol **AUTOMATIC BACKUPS (n)** + popup daftar dengan RESTORE (konfirmasi).
- Tes memakai `Game.backup_dir` sementara; dengan `persist = false` folder asli tidak pernah disentuh.

## 2fl. Update batch 160 — Achievement Rank

- `DB.ACH_POINTS` (10 per achievement) dan `DB.ACH_RANKS` (Bronze 50, Silver 120, Gold 220, Platinum 340, Diamond 480, Legend 640 poin; tiap rank punya hadiah sekali klaim).
- `Game.ach_points / ach_rank / ach_rank_name / ach_rank_state / claim_ach_rank / ach_ranks_ready`; klaim tersimpan di `s["ach_ranks"]`. Berlaku surut karena dihitung dari `s["achievements"]`.
- `quests.gd::_rank_panel`: panel di atas filter kategori (rank, poin, sisa poin ke rank berikut, 6 tombol rank: CLAIM / ✓ / syarat poin; tap rank terkunci menampilkan hadiahnya). CLAIM ALL dan badge Missions ikut menghitung rank.
- Commander Profile: baris "Achievements: <rank> • <poin> pts".

## 2fk. Update batch 159 — Arena Revenge

- Mode battle baru `"revenge"` (param `k` = kunci laporan). Entri `def_log` kini menyimpan `k`; laporan lama tanpa `k` tidak punya tombol.
- `Game.revenge_block(k)` / `revenges_ready()` / `revenge_team(k)` (5 hero dari seed `k`, hero pertama = wajah di laporan, level dicari supaya power tim paling dekat dengan power yang tercatat) / `apply_revenge_result(k, won)`: menang +14 RP (`REVENGE_RP`) dan 30 Arena Coin; tiap laporan hanya satu kali percobaan (`tried`), tanpa tiket.
- `arena.gd` tab DEFENSE: tombol **REVENGE** pada baris DEFEATED, label ✓ AVENGED setelah menang. `feature_badge("arena")` ikut menghitung revenge yang masih terbuka. Battle Prep menampilkan "One chance • +14 RP". Commander Records: mode "Arena Revenge".

## 2fj. Update batch 158 — Service record per hero + Hall of Fame

- `Game._record_heroes(won, sim)` (dipanggil dari `record_battle`): per hero milik pemain di sisi sekutu mencatat `b` (battle), `d` (damage dari event `hit` ber-`src`), `best` (damage terbesar satu battle), `ko`, dan `mvp` (damage tertinggi di battle yang menang). Disimpan di `s["stats"]["hero"]`. Hero support milik teman tidak dicatat.
- `Game.hero_record(id)` dan `Game.hall_of_fame(n)` (urut damage).
- `lobby.gd` tab RECORDS: panel **HALL OF FAME** (peringkat, wajah, bar damage, battle / MVP / KO). `hero_detail.gd` tab INFO: baris "Service: … battles • … damage • … MVP" dengan tooltip best battle dan KO.

## 2fi. Update batch 157 — SWEEP ALL untuk Daily Dungeon

- `Game.dungeon_sweeps_ready()`: jumlah sweep yang bisa dijalankan sekarang (sisa attempt semua dungeon yang sudah punya difficulty ter-clear).
- `Game.sweep_all_dungeons()`: memanggil `sweep_dungeon(id, dungeon_cleared(id))` sampai attempt habis, untuk tiap dungeon. Hasil `{rewards, runs, by}`. Dungeon yang belum pernah di-clear dilewati.
- `dungeon.gd`: tombol **SWEEP ALL (n)** di header. `main.gd::show_daily_board`: tombol **SWEEP n** di baris Daily Dungeons, lalu kembali ke board.

## 2fh. Update batch 156 — Quick Power-Up (tombol BOOST di Formation)

- `Game.power_up_plan()`: simulasi tanpa mengubah save. Hero di formation dinaikkan merata (selalu yang level terendah dulu, berhenti di `hero_cap`) dengan Hero EXP dan Gold yang ada. Hasil `{levels: {id: [dari, ke]}, exp, gold}`.
- `Game.power_up_team()`: menjalankan rencana itu lewat `level_up()`, lalu `auto_equip()` dan `auto_runes()` untuk tiap hero di formation. Hasil ditambah `gear`, `runes`, `before`, `after` (team power).
- `formation.gd`: tombol **▲ BOOST** di samping AUTO / CLEAR (juga di Battle Prep) → popup QUICK POWER-UP berisi level tiap hero (dari → ke, atau "Level cap" / "No change"), biaya, lalu POWER UP / CANCEL. Setelahnya toast "Team Power A → B (+N levels, N gear, N runes)".
- Flow test: rencana tidak mengubah save, biaya rencana = biaya nyata, level merata (selisih ≤ 1), panggilan kedua tanpa sumber daya tidak mengubah apa pun.

## 2fg. Update batch 155 — Guild Tech (bonus permanen dari Guild Coin)

- `DB.GUILD_TECH` (4 tech: `vigor` HP, `edge` ATK, `bulwark` DEF masing-masing +0,6%/level, `focus` CRIT +0,4%/level), `GUILD_TECH_MAX` 10, `DB.guild_tech_cost(lv)` = 60 + 40 × lv Guild Coin (total 2.400 per tech).
- `Game.guild_tech_lv / guild_tech_block / upgrade_guild_tech / guild_tech_bonus`. Level tech tidak boleh melebihi level guild. Disimpan di `s["guild"]["tech"]`: tetap ada saat pindah guild, bonus hanya aktif selama berada di guild.
- `Game.stat_bonus()` menambahkan `guild_tech_bonus()` (hp/atk/def/crit), jadi ikut ke power, battle, arena, dan semua mode.
- `guild.gd`: tab **TECH** di panel kanan (ikon, level, bonus sekarang → berikutnya, bar, tombol harga; tooltip alasan bila belum bisa). `guild:tab=TECH` bisa dipakai sebagai parameter.
- Flow test: butuh guild, dibatasi level guild, biaya naik, bonus masuk `stat_bonus`, hilang saat keluar guild.

## 2ff. Update batch 154 — Arc 12: The Dreaming Lantern

- **4 chapter baru (45–48, total 48 chapter / 288 stage)** di `DB.CHAPTERS`: The Sleeping Cathedral (bos Dreambound Glytta), The Field Without Endings (Kara), The Star That Stayed (Gemora), The Butterfly's Cradle (Lumeira). Tiap chapter punya intro, mid, mid2, boss_lines, outro, pilihan VN, dan field mod.
- **Varian baru `dream`** (prefix `dream:`, nama "Dreambound X"): `UI.corrupt` (desat 0,55, tone 1,42/0,98/1,36, halo pink), `DB.base_id` / `name_of` / `theme_color`, deteksi di `vn_dialogue.gd`, label DREAMBOUND + modulate rose di `battle.gd`, masuk `DB.RIFT_VARIANTS`.
- Penutup Arc 11 diubah jadi pengantar Arc 12. Interlude `i12` "Breakfast, Awake" (req 288), title `dreamwalker`, achievement `ch48`, Story Link `dawn` "Good Morning" (Lumeira + Kara + Gemora), mail `arc12_dream` (tanpa gems/tiket).
- `story.gd`: tab ARC 12 (chapter 44+) dan nama arc di `_arc_name`.
- Flow test: 48 chapter / 288 stage, nama varian, setiap chapter baru berakhir dengan bos Dreambound, semua speaker dialog valid.

## 2fe. Update batch 153 — Training Ground (uji damage tim)

- Mode battle baru `"training"` (params `elem`, `spar`): `Game.enemies_for` mengembalikan satu partner ber-flag `raid` (HP tak habis) dari `DB.training_dummy(elem)`, level = rata-rata tim; DUMMY `atk_mult` 0,02, SPARRING `atk_mult` 1,3 dan +3 level.
- `DB.training_dummies()`: satu musuh per kelompok elemen yang punya musuh (saat ini FIRE, WATER, WIND, EARTH, DARK).
- `Game.apply_training_result(elem, spar, dmg)` → `{prev, record}`; rekor di `s["training"]["best"]` per `elem[:spar]`, `training_best()`. Gratis: tidak ada `pay_battle`, tidak memakai meal (`meal_consume`), tidak masuk `record_battle` (supaya achievement jumlah battle tidak bisa di-farm).
- `battle.gd`: cabang `"training"` di `_finish` + `_show_training_result` (total damage, NEW RECORD, bar kontribusi per hero, TRAIN AGAIN / CONTINUE).
- `game/screens/training.gd` (baru): aturan + tim di kiri, kartu partner per elemen (kelemahan, rekor DUMMY/SPARRING, tombol TRAIN / SPAR). Terdaftar di `main.gd SCREENS`, `DB.MENU_FEATURES` / `MENU_SECTIONS` (EVENTS & PRACTICE), `FEATURE_UNLOCK` Lv.4, tutorial `training`.
- `tools/smoke.sh`: layar `training` dan satu battle training sampai CONTINUE.

## 2fd. Update batch 152 — Arena Defense (serangan saat pemain pergi)

- `Game.arena_defend_away(secs)` dipanggil di `_ready()` setelah `capture_away()`: 1 serangan per 3 jam absen (`DEF_EVERY_SEC`), maksimal `DEF_MAX` (5). Kekuatan penyerang 0,7–1,3× `team_power()`; peluang bertahan `defence_chance(ratio)` = 0,5 + (1 − ratio) × 1,6, dijepit 12%–90%.
- Bertahan: +6 RP dan 12 Arena Coin (ditampung di `def_coins`, dibayar `claim_defence()` saat tab dibuka). Kalah: −8 RP (tidak bisa di bawah 0). Log `s["arena"]["def_log"]` maksimal 20 entri, `def_new` = belum dilihat. Statistik `def_wins` / `def_losses`.
- `arena.gd`: tab **DEFENSE** (`_render_defence`) dengan rekor, aturan, tombol EDIT DEFENSE TEAM (ke Formation), dan daftar serangan (wajah, nama, power, waktu, DEFENDED/DEFEATED, ±RP). Badge jumlah serangan baru di tab; `arena:tab=DEFENSE` bisa dipakai sebagai parameter.
- `feature_badge("arena")` = serangan yang belum dilihat. Welcome Back menambah baris ringkasan serangan.
- Tidak aktif sebelum Arena terbuka (Lv.5) atau bila absen < 3 jam.

## 2fc. Update batch 151 — Wishlist di Standard Summon

- `DB.WISH_MAX` (3) dan `DB.WISH_RATE` (0,5). `Game.wishlist()` / `toggle_wish(id)` menyimpan pilihan di `s["gacha"]["wish"]` (hanya SSR, id yang sudah tidak ada dibuang).
- `Game.pull()`: di banner tanpa `featured`, hasil SSR punya peluang 50% diganti hero acak dari wishlist (`res["wished"] = true`). Rate SSR, pity, dan banner rate-up tidak berubah.
- `gacha.gd`: `_wish_row()` (3 slot wajah + EDIT WISHLIST, tampil di panel meter banner Standard) dan `_show_wishlist()` (popup kartu semua SSR, tag ♥ WISH pada yang dipilih, toast bila penuh).
- `hero_card.gd`: kartu sempit (< 110 px) memakai ikon gembok saja; sebelumnya teks "NOT OWNED" terpotong (juga di popup RATES).
- Flow test: batas 3 hero, non-SSR ditolak, pity di banner Standard memberi hero wishlist ±50%.

## 2fb. Update batch 150 — Schedule (kalender semua timer + ulang tahun)

- `Game.schedule()`: baris `{icon, name, note, left, route, color}` untuk Daily Reset, Weekly Reset, Event (plus event berikutnya), Festival (plus festival bulan depan), Season Pass, Arena Season, World Boss Week dan Starlight Rift. Fitur yang masih terkunci level tidak tampil.
- `Game.left_text(secs)` (format hitung mundur), `Game.days_until("MM-DD")`, `Game.upcoming_birthdays(n, owned)`.
- `main.gd::show_schedule()`: popup SCHEDULE, hitung mundur diperbarui tiap detik (`Timer`), merah bila < 1 hari, tombol GO per baris, 4 ulang tahun terdekat di bawah (hero yang belum dimiliki diredupkan). Tombol **SCHEDULE ▶** di Today's Board dan **◀ TODAY** untuk kembali.
- Perbaikan: `Game.birthday_in_year()` — hero berulang tahun 29 Februari kini dirayakan 28 Februari di tahun non-kabisat (sebelumnya hadiahnya hanya muncul 4 tahun sekali). Dipakai `birthday_heroes()` dan `days_until()`.
- `tools/shot_runner.gd`: step `schedule`.

## 2fa. Update batch 149 — COLLECT ALL di Today's Board

- `Game.collectables()`: daftar `[label, jumlah]` semua yang bisa diambil tanpa bermain (AFK ≥ 60 dtk, Login Bonus, hadiah Mail, misi harian/mingguan yang siap, Season Pass, Friend Hearts, Guild Check-in, Kitchen Basket, Expedition selesai). Fitur yang masih terkunci level tidak ikut.
- `Game.collect_all()`: mengklaim semuanya lewat fungsi klaim yang sudah ada (jadi progres misi, EXP pass, bond ekspedisi tetap jalan), misi diklaim dua putaran karena klaim bisa menyelesaikan misi lain. Mengembalikan `{rewards, done}`.
- `main.gd::show_daily_board`: panel "Ready now: …" + tombol **✦ COLLECT ALL** di atas daftar; setelah klaim muncul popup ALL COLLECTED lalu toast "Collected: …".
- Perbaikan: `burst_fx.gd::_star` tidak lagi menggambar bintang berukuran hampir nol (memicu spam error "Invalid polygon data, triangulation failed" di akhir animasi popup hadiah).
- Flow test: fresh save → collect_all mengambil login + mail, panggilan kedua kosong.

## 2ez. Update batch 148 — 37 achievement baru + filter kategori

- `DB.ACHIEVEMENTS`: 37 entri baru (total 70) untuk sistem yang sebelumnya tanpa achievement: jumlah battle, win streak, 3★, Arena, Tower 50/100, Boss Hunt, Rift, Hero Trial, Commander Lv, Awaken A5, Limit Break, gear SSR/+10, Bond 10, 5 Oath, date, PERFECT date, foto, foe jinak, Special Skin, level Guild, hari login, Gold terpakai.
- `Game.stat_value`: stat baru `battles`, `best_streak`, `flawless`, `days`, `gold_spent`, `photos` (dari Commander Records), `kills_total` (jumlah Bestiary, jadi berlaku surut), `arena_wins`, `hunt_clears`, `rift_best`, `trials`, `commander_level`, `max_awaken`, `max_lb`, `gear_ssr`, `gear_max`, `bond_max`, `dates`, `perfect_dates`, `tamed`, `special_skins`, `guild_level`.
- `DB.ACH_CATS` / `ACH_CAT_OF` / `ach_cat()`: kategori per stat. `quests.gd::_cat_chips`: baris chip filter di atas daftar (ALL + 5 kategori) dengan `selesai/total` dan titik bila ada yang siap diklaim.
- `DB.QUEST_ROUTE` + `ROUTE_ICON` dilengkapi supaya tiap achievement baru punya tombol GO dan ikon.
- Target sengaja di luar jangkauan hari pertama, jadi ekonomi day-one tidak berubah (flow test PASS).

## 2ey. Update batch 147 — Commander Records (statistik seumur hidup)

- **Tab RECORDS** di Commander Profile (`lobby.gd::_open_profile`, tab ketiga setelah TITLES/AVATAR): panel JOURNEY, BATTLE, ECONOMY dan BATTLES BY MODE dari `Game.records()`.
- **Pencatatan** di `s["stats"]` lewat `Game.stat_add / stat_max / stat`:
  - `Game.record_battle(mode, won, stars, sim)` dipanggil sekali per battle sungguhan (`battle.gd::_finish` dan `quick_battle`): `battles`, `wins`, `flawless` (3★), `streak`/`best_streak`, `damage`/`best_damage` (jumlah event hit/dot ke sisi musuh), `best_power`, `m_<mode>`.
  - `give()` mencatat `gold_earned`/`gems_earned`; `spend()` mencatat `gold_spent`/`gems_spent`/`energy_spent`.
  - `record_kills` → `kills`; `pull` → `ssr_pulled`; semua fungsi sweep → `sweeps`; `_check_day` → `days` dan `since` (hari pertama pencatatan); `_process` → `play_sec`.
- Save lama: angka mulai dihitung sejak update ini (tanggalnya tampil di "Recording since").
- Flow test: battle menambah battles/damage, kalah memutus streak, spend/give tercatat.

## 2ex. Update batch 146 — Ultimate & skill di battle tidak tersendat, sprite Ex-Nymph dikembalikan

- **Ultimate backdrop di-batch**: `game/ui/ult_backdrop.gd` (baru) menggantikan closure `deco` di `battle.gd::_ultimate`. Bentuk & urutan gambar sama (AABatch), bagian diam (glow, 2 ring, halftone) dibangun sekali. Draw call 426 → 5; diff piksel maks 1/255 (~40 piksel).
- **Art skill dimuat sebelum battle**: `DB.warm_battle_art(id, ally, boss, skin)` (face + cutin + art ultimate SSR, aturan sama dengan pemicu cut-in). `game/ui/warmer.gd` (baru) menjalankan 1 job/frame di layar Battle Prep (formation dengan mode) saat layar tidak disentuh. `battle.gd::_preload_art()` sebagai cadangan (hit cache bila sudah dipanaskan). Texture yang dimuat di tengah battle: 13+ → ~1; buka battle setelah prep ±34 ms.
- **Ex-Nymph**: sprite chibify (batch 136) dihapus, `sprites: []` lagi di `character_database.json` → battle memakai art utama (permintaan user, wajah rusak).

## 2ew. Update batch 145 — Semua layar terbuka lebih cepat (gambar dimuat bertahap)

Waktu `main.go()` kunjungan pertama (Mac Intel, semua fitur terbuka):

| Layar | Sebelum | Sesudah |
|---|---|---|
| Gallery | 2.192 ms | 326 ms |
| Arena | 1.349 ms | 264 ms |
| Wardrobe | 918 ms | 353 ms |
| Date | 866 ms | ~400 ms |
| Bestiary | 831 ms | 109 ms |
| Hunt | 825 ms | 249 ms |
| Friends | 810 ms | 120 ms |
| Gacha | 803 ms | 287 ms |
| Event / Tower | 413 / 379 ms | 263 / 228 ms |

- Penyebab: potongan wajah (`DB.face`) dan thumbnail butuh art full-body dimuat dulu, puluhan sekaligus.
- `game/ui/lazy_tex.gd` (baru): child node di TextureRect yang mengisi texture di frame berikutnya; semua antrian berbagi budget ~8 ms per frame (minimal 1 per frame), urutan tree ≈ urutan tampilan, fade-in 0,18 dtk. Texture-nya persis sama.
- `UI.tex_rect_lazy(ready, loader, size, cover)`, `UI.face_rect(id, size, skin)`, `UI.art_rect(id, idx, size, cover)`; `DB.face_ready()`, `DB.art_ready()`, `DB.portrait_path()`. Kalau gambar sudah di cache → langsung dipasang seperti dulu.
- `HeroCard` opsi `lazy` sekarang memakai LazyTex (antrian khusus di heroes.gd dihapus); dipakai di Heroes, Date, Friends, Room, daftar rate Gacha.
- Art utama (hero besar di tengah layar, hasil gacha) sengaja tidak di-lazy-kan.
- Verifikasi: screenshot setelah semua gambar termuat sama dengan versi lama (beda hanya partikel/animasi). Tes flow + smoke PASS.

## 2ev. Update batch 144 — Layar Heroes langsung terbuka

| Ukuran (Mac Intel, kunjungan pertama) | Sebelum | Sesudah |
|---|---|---|
| `main.go("heroes")` (layar membeku) | ~2.500 ms | ~480 ms |
| Kunjungan kedua | ~330 ms | ~220 ms |
| FPS di layar Heroes | 60 | 60 (tidak berubah) |

- Penyebab: 37 kartu memuat art full-body (WebP 1200 px, 20–380 ms per gambar) secara sinkron sebelum layar tampil.
- `HeroCard` opsi `lazy`: kalau art belum ada di `DB._tex_cache`, kartu dibuat tanpa art; `load_art()` memasang art yang sama lalu fade-in 0,18 dtk. `heroes.gd` `_art_queue` memuat art per frame dengan budget ~8 ms, urut sesuai tampilan (selaras dengan animasi stagger). Kunjungan berikutnya: art sudah di cache → langsung tampil seperti biasa.
- `DB.art_list()` di-cache (dulu `ResourceLoader.exists` per outfit tiap panggilan, ~1,6 ms); mengembalikan salinan. Baru: `DB.art_path()`, `DB.tex_loaded()`.
- Verifikasi: screenshot layar Heroes setelah semua art termuat sama dengan versi lama (beda hanya kilau header yang beranimasi). Tes `clip_children` pada kartu: tidak berpengaruh ke fps, jadi tidak diubah.
- Belum: Wardrobe (~830 ms pertama kali, crop wajah butuh art penuh skin spesial).

## 2eu. Update batch 143 — Draw call dipangkas (grafis tetap sama)

| Bagian | Sebelum | Sesudah |
|---|---|---|
| Formation (frame) | 28–47 ms, ~857 draw call | 16,7 ms (60 fps, batas vsync), ~200 draw call |
| Battle (frame) | 31–56 ms, ~800 draw call | 17–23 ms, ~200 draw call |
| Lobby | 476 draw call | 274 draw call, 60 fps |
| Story map | 544 draw call | 309 draw call, 60 fps |

- Temuan: setelah batch 142, sisa lag ada di sisi render. Tiap `draw_polyline(..., true)` = 3 draw call, tiap lingkaran/poligon = 1 draw call. Papan grid saja ±270 draw call per papan (Intel/WebGL: ~25 µs per draw call).
- `game/ui/aa_batch.gd` (baru): port baris-per-baris dari Godot 4.7.2 `canvas_item_add_polyline` / `add_line` / `add_ellipse` / `add_polygon` / `draw_arc` / `draw_rect`, dikumpulkan jadi SATU `canvas_item_add_triangle_array`. Urutan segitiga sama → blending sama. Warna garis dibulatkan ke half-float seperti renderer GL. Tes: 0 piksel beda (811 → 2 draw call).
- `grid_board.gd`: sel diam di-cache per sel (geometri tetap); sel highlight/terpilih di layer `_live` (sel berjarak 8 px, outline < 4 px → tidak ada tumpang tindih, piksel sama). Rune: geometri di-cache per langkah putaran (240 langkah per TAU/6), digeser dengan `Transform2D * PackedVector2Array` (C++), 1 draw call untuk 9 sel.
- `unit_view.gd`: elips dasar direkam sekali; 3 busur berputar di child `arcs`, di-cache per langkah (720 per TAU/3).
- `story.gd` StageNode/StageShade: satu batch; stage aktif dipecah layer (bayangan → halo denyut → rim statis → busur berputar ter-cache) sesuai urutan asli.
- `festival_fx.gd` / `ambient_fx.gd`: semua bentuk satu partikel = 1 draw call (garis hujan tetap native karena sudah di-batch Godot lintas node).
- Verifikasi piksel (lama vs baru, state sama): papan/partikel/medali statis 0 beda; lentera maks 1/255; bagian berputar maks 3–7/255 di tepi (pembulatan langkah putaran, ≈0,05–0,1 px).
- Catatan: menghitung geometri di GDScript itu mahal (~0,1 ms per polyline), jadi semua yang beranimasi WAJIB di-cache, jangan dibangun ulang tiap frame.

## 2et. Update batch 142 — Performa lebih lancar (grafis identik)
- **Masalah:** di build web/iPhone lobby terasa lag. Penyebab utamanya, efek partikel menggambar ulang semua bentuknya dari nol setiap frame (ribuan lingkaran/polygon per frame). Di Mac uji, lobby hanya ~13 fps.
- **`FestivalFX` & `AmbientFX`** (lentera, kunang-kunang, salju, kelopak, daun, hati, hujan, butiran cahaya):
  - Setiap partikel kini jadi `Node2D` sendiri (`_Part` / `_Mote`) yang bentuknya direkam sekali dan direkam ulang hanya saat respawn.
  - Tiap frame cukup `position`, `rotation` dan `modulate.a` (kedip/flicker) yang berubah.
  - Tali lentera tetap digambar ulang tiap frame (satu garis), supaya goyangannya persis sama.
- **Peta Story:** jalur (polyline anti-alias tebal) kini digambar sekali. Hanya titik cahaya yang mengalir di jalur yang sudah clear yang digambar ulang tiap frame, di lapisan `_flow_layer` (anak pertama `_map_layer`, tetap di bawah medali stage).
- **`GridBoard` (papan battle/formation):** rune yang berputar dipindah ke lapisan anak `_runes` (redraw tiap 3 frame seperti sebelumnya). Petak, bingkai dan bracket tidak digambar ulang lagi saat diam. Highlight dan sel terpilih tetap redraw tiap frame.
- **Verifikasi grafis:** render deterministik (seed dan langkah tetap) lama vs baru dibandingkan per piksel.
  - Semua jenis partikel dan papan (diam, terpilih, highlight) beda 0 piksel.
  - Kunang-kunang beda 1/255 di 12 piksel (pembulatan), tidak terlihat mata.
- **Hasil di Mac uji (Intel Iris 6100):**

  | Layar | Sebelum | Sesudah |
  |---|---|---|
  | Lobby | ~13 fps | ~37–40 fps |
  | Story | ~12–18 fps | ~39 fps |

  Battle juga lebih ringan karena atmosfer partikel dan papannya ikut dioptimasi.

## 2es. Update batch 141 — Progress bar mengilap & tab aktif bercahaya
- **Progress bar** (`UI.bar` → `UI._bar_gloss`, hanya varian default/`GoldBar` dengan tinggi ≥ 8px; `HpBar` di battle tidak disentuh):
  - Kilap putih tipis di sepertiga atas bagian yang terisi, plus sapuan cahaya pelan. Keduanya terpotong mengikuti panjang isi bar dan mengikuti `value_changed`.
  - Isi naik dari kosong: bar yang dibuat dalam 450 ms setelah `main.go()` (lewat meta `Game.screen_t`) terisi dari 0 ke nilainya dalam 0,7 detik.
- **Tab aktif** (`UI._tab_marker`, otomatis untuk semua `TabButton`): garis emas bercahaya di bawah tab yang aktif, tumbuh dari tengah. Muncul lewat sinyal `toggled` dan saat `ready`.
- Toast untuk fitur yang masih terkunci ("unlocks at", "locked") kini memakai ikon 🔒.
- Semua efek mati saat Reduce Effects aktif.

## 2er. Update batch 140 — Ripple sentuh, toast baru, header hidup
- **Ripple sentuh** (`game/ui/ripple.gdshader`, `UI.ripple()`): setiap tombol yang memakai `UI.hover_fx` (semua `UI.button`) memunculkan lingkaran cahaya lembut yang menyebar dari titik sentuh, terpotong rapi mengikuti sudut tombol. Tidak muncul pada tombol disabled.
- **Toast baru** (`main.gd toast()`):
  - Masuk dengan efek jatuh-memantul, lalu keluar sambil mengecil dan memudar.
  - Punya badge ikon bulat di kiri (`_toast_glyph`): ✦ unlock/new, ▲ level/rank, ! peringatan (not enough/need/full), ✓ selesai/klaim/simpan, ★ lainnya. Ada juga sapuan kilau tipis.
  - Bug tween diperbaiki: fade-out sekarang benar-benar menunggu 2,4 detik.
- **Header layar** (`screen.gd`):
  - `_header_intro`: judul muncul dengan pop, garis emas tumbuh dari tengah, chip mata uang jatuh satu per satu.
  - `_chip_pulse`: saat Gold/Gems berubah, chip membesar sesaat dan berkedip (emas jika bertambah, merah jika berkurang), lalu muncul angka +/− melayang.
- Semua efek mati saat Reduce Effects aktif.

## 2eq. Update batch 139 — Polesan tampilan & animasi UI
- **Kilau sapuan cahaya di tombol emas** (`game/ui/shine.gdshader`, `UI.shine()`):
  - Semua `GoldButton` dari `UI.button` otomatis mendapat sapuan cahaya diagonal tiap ±3,6 detik, dengan fase acak supaya tidak serempak.
  - Tersembunyi saat tombol disabled. Mati jika Reduce Effects aktif.
- **Popup lebih halus** (`main.gd`):
  - Latar gelap kini fade-in.
  - Saat ditutup, panel mengecil dan memudar (`_dismiss`). Layer langsung berhenti dihitung sebagai popup dan semua kontrolnya tak bisa diklik, jadi tidak ada klaim ganda.
  - Bug diperbaiki: `UI.pop` dulu membesar dari pojok kiri-atas karena ukuran panel masih 0. Pivot sekarang mengikuti `resized`.
- **Popup hadiah lebih meriah:**
  - Ikon jatuh dengan pantulan squash-and-stretch.
  - Lalu muncul ledakan kilau (`game/ui/burst_fx.gd`) dengan warna sesuai jenis hadiah: pink untuk premium (shard/skin/tiket/oath ring/celestial), biru untuk Gems, hijau untuk potion/EXP, emas untuk lainnya.
- `tools/shot_runner.gd`: `press:` / `pressok` melewati tombol di popup yang sedang menutup.
