# ⚔️ Hybrid Anime Combat Engine (Storm 4 + Tekken + MUGEN 14)

Sebuah framework pertempuran anime 3D mutakhir di Roblox yang menggabungkan tiga pilar game pertarungan legendaris:
1. **Naruto Shippuden: Ultimate Ninja Storm 4 / Connections**: Dynamic Dual-Target Lock-On Camera, Homing Ninja Dash, Circular Orbital Strafing, Assist Striker Summon, dan Leader Swap.
2. **Tekken**: Technical Stance Defense (High Guard vs Low Guard), 3D Double-Tap Sidestep Evasion, Guard Health Meter (dengan Guard Crush Stun), dan 180ms Just-Frame Parry Counter.
3. **Jump Force MUGEN 14**: 4-Hit M1 Attack String dengan forward lunging, Low Shinobi Sweep, dan modular 5-class archetype architecture (Rushdown, Zoner, Grappler, Sword, Trickster).

---

## 🎮 Kontrol Pertarungan

| Aksi | Tombol / Input | Keterangan |
| :--- | :--- | :--- |
| **Basic Attack Combo** | `Klik Kiri (M1)` | 4-hit string (Jab -> Cross -> Uppercut Lift -> Sonic Finisher Knockback) |
| **Low Shinobi Sweep** | `Ctrl + M1` | Sapuan bawah: **Menembus High Guard** (hanya bisa ditangkis Low Guard) |
| **High / Mid Guard** | Tahan `F` | Pelindung Cyan: Menahan serangan High & Mid |
| **Low Guard** | Tahan `Ctrl + F` | Pelindung Amber: Menahan sapuan bawah (*Low Sweep*) |
| **Just-Frame Parry** | Tekan `F` (180ms) | Menangkis serangan tepat waktu -> Lawan terkena **Stagger Stun 1.15s** |
| **Tekken Sidestep** | Double-tap `A` / `D` | Menghindar menyamping secepat kilat dengan efek motion blur trail |
| **Homing Ninja Dash** | Double-tap `Space` | Melesat cepat (85 studs/dtk) mengunci lawan dengan efek sonic burst |
| **Assist Striker** | Tekan `T` | Memanggil partner jutsu (menembakkan proyektil energi, 20s cooldown) |
| **Leader Swap** | Tekan `G` | Berganti peran dengan partner (tag-team combo continuation) |
| **Toggle Lock-On** | Tekan `Z` / Klik Tengah | Mengaktifkan / mematikan kamera dual-framing dinamis |

---

## 📂 Struktur Proyek

```
d:\VIBE CODE\combat\
├── default.project.json           # Konfigurasi sync Rojo
├── MasterCombatInstaller.luau     # Single-file auto installer untuk Roblox Studio
├── generate_master_installer.py   # Script generator installer
├── README.md                      # Dokumentasi lengkap
└── src/
    ├── shared/
    │   └── CombatConfig.luau              # Konfigurasi kamera, movement, defense, combo & archetypes
    ├── server/
    │   ├── CombatServerMaster.luau        # Validasi hit, defense/parry server, jutsu striker
    │   └── TrainingDummySpawner.luau      # NPC Training Dummy interaktif (bisa ganti mode guard)
    └── client/
        ├── StormCameraController.luau     # Kamera dual-framing dinamis + reticle lock-on HUD
        ├── StormMovementController.luau   # Orbital strafing, Tekken sidestep, Ninja Dash
        ├── TekkenDefenseController.luau   # High/Low guard stances, guard meter HUD, parry VFX
        ├── CombatComboController.luau     # M1 attack combo 4-hit, Low sweep, hitbox detection
        └── StormAssistController.luau     # Assist striker summon & Leader Swap
```

---

## 🚀 Cara Pemasangan di Roblox Studio

### Cara 1: Menggunakan Command Bar (Paling Cepat & Praktis)
1. Buka tempat / game Anda di **Roblox Studio**.
2. Buka jendela **Command Bar** (menu `View` -> `Command Bar` atau tekan `Ctrl + \``).
3. Salin seluruh isi file [`MasterCombatInstaller.luau`](./MasterCombatInstaller.luau).
4. Paste ke dalam Command Bar, lalu tekan **Enter**.
5. Seluruh RemoteEvent, folder, server script, dan client script akan terpasang otomatis dalam 1 detik.
6. Tekan **Play (F5)** untuk memulai pertarungan!

### Cara 2: Menggunakan Rojo
Jika Anda menggunakan ekstensi Rojo:
```bash
rojo serve default.project.json
```
Lalu hubungkan plugin Rojo di Roblox Studio.
