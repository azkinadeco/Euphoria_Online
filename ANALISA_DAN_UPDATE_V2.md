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

## 3. Yang BELUM ada (butuh keputusan/aset tambahan)

- **Online sungguhan** (akun, server, PvP real-time, guild, chat, anti-cheat): butuh backend (mis. Nakama, PlayFab, Firebase). Saat ini semua lokal (offline).
- **Pembayaran / top-up uang asli**: belum ada; shop memakai Gems/Gold/Arena Coin.
- **Friend, Guild & Event** sudah ada, tapi teman/anggota masih simulasi (belum multiplayer).
- **Animasi Live2D/Spine & voice acting**: hero memakai gambar statis + animasi "napas"/lunge. Butuh rig Spine/Live2D dan file suara.
- **Hero Mora & musuh Ygg-Naar/Ex-Nymph** belum punya sprite chibi → memakai artwork penuh. Musuh di `enemy/Belum bisa dipakai` tidak dipakai.

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
