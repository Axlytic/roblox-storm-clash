# ⚔️ STORM CLASH (Hybrid Anime Combat Engine)

[![GitHub Repo](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/Axlytic/roblox-storm-clash)
[![Platform](https://img.shields.io/badge/Platform-Roblox%20(PC%20%7C%20Mobile%20%7C%20Console)-red)](https://www.roblox.com/games/102495036901929/Storm-Clash)
[![Roster](https://img.shields.io/badge/Playable%20Fighters-24%20Anime%20Legends-orange)](#-roster-24-karakter-anime-otentik)
[![Orientation](https://img.shields.io/badge/Mobile-Strict%20Landscape-green)](#)

Sebuah framework pertempuran anime 3D mutakhir di Roblox yang menggabungkan tiga pilar game pertarungan legendaris:
1. **Naruto Shippuden: Ultimate Ninja Storm 4 / Connections**: Dynamic Dual-Target Lock-On Camera, Homing Ninja Dash, Shinobi Run Blending (28° Torso lean, -65° Arms sweep), Shuriken/Jutsu jarak jauh, Chakra Charge & Cinematic Ultimate Secret Technique (Ougi), Substitution Jutsu (Kawarimi log teleport), Assist Striker Summon, dan Leader Swap.
2. **Tekken**: Technical Stance Defense (High Guard vs Low Guard), 3D Double-Tap Sidestep Evasion, Guard Health Meter (dengan Guard Crush Stun), dan 180ms Just-Frame Parry Counter.
3. **Jump Force MUGEN 14 & Anime Mega-Roster**: 24 Karakter Anime Legendaris lintas waralaba populer dengan model morph 3D prosedural, moveset otentik, dan sistem proyektil dinamis.

---

## 🎮 Skema Kontrol Terkini (PC, Mobile & Gamepad)

| Aksi | Keyboard PC | Gamepad | Mobile Touch | Keterangan Mekanik |
| :--- | :---: | :---: | :---: | :--- |
| **Substitution (Kawarimi)** | `E` / `Q` | `L2` / `LT` | `[🪵 SUB]` | Teleportasi 8 stud ke belakang musuh meninggalkan balok kayu 3D (4 Stok) |
| **Attack (M1 String)** | `J` | `Square` / `X` | `[⚔️ PUNCH]` | 4-Hit Combo (Neutral, Up Air-Launcher, Down Rebound, Air Combo) |
| **Low Shinobi Sweep** | `S + J` / `K` | `Down + Square` | `[⚡ LOW]` | Sapuan bawah: **Menembus High Guard** |
| **High / Mid Guard** | Tahan `F` | Tahan `R1` / `R2` | `[🛡️ GUARD]` | Menahan serangan atas & tengah (Reduksi 80% damage) |
| **Low Guard** | Tahan `S + F` | Tahan `Down + R1` | `[🛡️] (Nunduk)`| Menahan sapuan bawah (*Low Sweep*) |
| **Just-Frame Parry** | Tekan `F` (180ms) | Tekan `R1` (180ms) | Tap `[🛡️]` | Menangkis tepat waktu -> Lawan **Stagger Stun 1.15s** |
| **Storm Counter Attack** | `F + J` | `R2 + Square` | `[🛡️] + [⚔️]` | Kuda-kuda counter: memantulkan musuh 55 stud + stun 1.3s |
| **Homing Ninja Dash** | `Shift` / Spasi x2| `Circle` / `B` | `[💨 DASH]` | Meluncur cepat (85 studs/dtk) mengunci musuh |
| **Tekken Sidestep** | Double-tap `A` / `D` | DPad L/R x2 | Swipe Layar | Menghindar menyamping dengan jejak bayangan cyan khas Tekken |
| **Chakra Load** | `I` (Tap) | `Triangle` / `Y` | `[🔥 CHAKRA]` | Masuk ke mode Chakra Loaded (aura biru menyala) |
| **Character Ninjutsu** | `I` (Tap) + `J` | `Triangle + Square`| `[🔥] + [⚔️]` | Melepaskan jutsu signature karakter (Rasengan, Chidori, Red Hawk, dll) |
| **Chakra Dash (CDC)** | `I` (Tap) + `Shift`| `Triangle + X` | `[🔥] + [💨]` | Melesat 112 studs/s membelah proyektil & cancel kombo |
| **Shuriken / Ranged Jutsu**| `L` | `Circle` / `B` | `[🌀 RANGED]` | Melempar proyektil khusus (Rasen-Shuriken, Bola Api, Tinju Karet, dll) |
| **Ultimate Technique** | `I` (Hold $\ge 0.6$s)| Hold `Triangle` | Hold `[🔥]` | Cutscene Sinematik Letterbox 21:9 Finisher (52 DMG) saat Chakra 100% |
| **Support Assist Striker** | `T` | `L1` / `LB` | `[⚡ ASSIST]` | Memanggil partner jutsu bantuan dari samping |
| **Leader Swap** | `U` / `G` | `L2` / `LT` | `[🔄 SWAP]` | Berganti peran dengan partner di tengah pertarungan |
| **Roster Character Modal** | `B` | `Select` | `[👥 ROSTER]` | Membuka katalog 24 petarung anime lengkap dengan dossier statistik |

---

## 👥 Roster 24 Karakter Anime Otentik

1. **Naruto Uzumaki** (*Naruto Shippuden*) - Rushdown (Rasen-Shuriken & Rasengan)
2. **Sasuke Uchiha** (*Naruto Shippuden*) - Zoner (Goukakyuu Fireball & Chidori)
3. **Kakashi Hatake** (*Naruto Shippuden*) - Balanced (Lightning Hound & Raikiri)
4. **Madara Uchiha** (*Naruto Shippuden*) - Zoner (Majestic Destroyer & Susanoo)
5. **Monkey D. Luffy** (*One Piece*) - Grappler (Gum-Gum Pistol & Red Hawk)
6. **Roronoa Zoro** (*One Piece*) - Sword (36 Pound Phoenix & Oni Giri)
7. **Vinsmoke Sanji** (*One Piece*) - Rushdown (Poêle à Frire & Diable Flambage)
8. **Trafalgar D. Water Law** (*One Piece*) - Trickster (Takt Debris & Shock Wille)
9. **Son Goku** (*Dragon Ball*) - Balanced (Ki Blast Volley & Super Kamehameha)
10. **Vegeta** (*Dragon Ball*) - Rushdown (Big Bang Attack & Galick Gun)
11. **Future Trunks** (*Dragon Ball*) - Sword (Burning Attack & Shining Slash)
12. **Ichigo Kurosaki** (*Bleach*) - Rushdown (Getsuga Tensho & Black Getsuga)
13. **Sosuke Aizen** (*Bleach*) - Trickster (Kurohitsugi Coffin & Shunpo Thrust)
14. **Byakuya Kuchiki** (*Bleach*) - Sword (Senbonzakura Shikan & Utsusemi)
15. **Ryomen Sukuna** (*Jujutsu Kaisen*) - Rushdown (Dismantle Slash & Cleave)
16. **Satoru Gojo** (*Jujutsu Kaisen*) - Zoner (Cursed Blue & Red Repulsion)
17. **Yuji Itadori** (*Jujutsu Kaisen*) - Rushdown (Cursed Shockwave & Black Flash)
18. **Megumi Fushiguro** (*Jujutsu Kaisen*) - Trickster (Nue Lightning & Totality Claws)
19. **Killua Zoldyck** (*Hunter x Hunter*) - Trickster (Narukami & Godspeed Lightning)
20. **Gon Freecss** (*Hunter x Hunter*) - Grappler (Jajanken Paper & Scissors & Rock)
21. **Tanjiro Kamado** (*Demon Slayer*) - Sword (Striking Tide & Hinokami Kagura)
22. **Zenitsu Agatsuma** (*Demon Slayer*) - Trickster (Thunder Spark & Hekireki Issen)
23. **Izuku Midoriya (Deku)** (*My Hero Academia*) - Rushdown (Delaware Smash & St. Louis Kick)
24. **Katsuki Bakugo** (*My Hero Academia*) - Rushdown (Stun Grenade & AP Shot)

---

## 🛡️ Sistem Otomatis Anti-Bolong GitHub Streak

Proyek ini telah dilengkapi dengan sistem pengingat dan sinkronisasi otomatis di level sistem operasi Windows:
* **Pengingat Desktop Harian (`scripts/daily_streak_reminder.ps1`)**: Muncul otomatis di desktop via banner notifikasi Windows setiap jam 18:00 WIB dan saat login ke Windows.
* **Auto-Git Sync Guard (`scripts/auto_git_sync.ps1`)**: Berjalan otomatis via Windows Task Scheduler setiap jam 21:00 WIB untuk auto-commit dan auto-push perubahan hari itu langsung ke GitHub, memastikan streak grafik kontribusi tetap menyala tanpa putus.
