# ⚔️ STORM CLASH (Hybrid Anime Combat Engine)

Sebuah framework pertempuran anime 3D mutakhir di Roblox yang menggabungkan tiga pilar game pertarungan legendaris:
1. **Naruto Shippuden: Ultimate Ninja Storm 4 / Connections**: Dynamic Dual-Target Lock-On Camera, Homing Ninja Dash, Circular Orbital Strafing, Assist Striker Summon, dan Leader Swap.
2. **Tekken**: Technical Stance Defense (High Guard vs Low Guard), 3D Double-Tap Sidestep Evasion, Guard Health Meter (dengan Guard Crush Stun), dan 180ms Just-Frame Parry Counter.
3. **Jump Force MUGEN 14**: 4-Hit M1 Attack String dengan forward lunging, Low Shinobi Sweep, dan modular 5-class archetype architecture.

---

## 🎮 Skema Kontrol Lengkap (PC / Laptop, Mobile & Gamepad)

### 💻 Keyboard PC & Laptop (WASD + IJKL Layout)

| Aksi | Tombol Utama | Tombol Alternatif | Keterangan |
| :--- | :--- | :--- | :--- |
| **Movement** | `W, A, S, D` | Arrow Keys | Gerakan melingkar (Orbital strafe) mengitari lawan |
| **Attack (M1 String)** | `J` | `Klik Kiri (M1)` | 4-hit string (Jab -> Cross -> Uppercut -> Finisher) |
| **Low Shinobi Sweep** | `S + J` | `Ctrl + J` / `Ctrl + M1` | Sapuan bawah: **Menembus High Guard** |
| **High / Mid Guard** | Tahan `K` | Tahan `F` | Pelindung Cyan: Menahan pukulan atas & tengah |
| **Low Guard** | Tahan `S + K` | Tahan `Ctrl + K` / `Ctrl + F` | Pelindung Amber: Menahan sapuan bawah (*Low Sweep*) |
| **Just-Frame Parry** | Tekan `K` (180ms) | Tekan `F` (180ms) | Menangkis tepat waktu -> Lawan **Stagger Stun 1.15s** |
| **Homing Ninja Dash** | `L` | Double-tap `Space` | Meluncur cepat (85 studs/dtk) mengunci musuh |
| **Tekken Sidestep** | Double-tap `A` / `D` | - | Menghindar menyamping dengan jejak bayangan cyan |
| **Assist Striker** | `I` | `T` | Panggil partner jutsu (tembakan energi, cooldown 20s) |
| **Leader Swap** | `U` | `G` | Berganti peran dengan partner (tag-team synergy) |
| **Toggle Lock-On** | `Z` | `Klik Tengah Mouse` | Mengaktifkan / mematikan kamera dual-target Storm 4 |

---

### 📱 Layar Sentuh Mobile & Tablet
* **Action Cluster di Jempol Kanan**:
  * Tombol **⚔️ ATTACK [J]** (Ukuran besar, mudah di-tap)
  * Tombol **🛡️ GUARD [K]** (Bisa di-hold untuk bertahan, tap untuk parry)
  * Tombol **💨 DASH [L]** (Ninja Dash instan)
  * Tombol **⚡ ASSIST [I]** (Panggil partner jutsu)
  * Tombol **🔄 SWAP [U]** (Leader Swap)
  * Tombol **📱 TOUCH: ON/OFF** di pojok kanan atas untuk uji coba di PC.

---

### 🎮 Stik / Controller Gamepad (PlayStation & Xbox)
* **Attack**: Tombol `Square` (PS) / `X` (Xbox)
* **Ninja Dash**: Tombol `Circle` (PS) / `B` (Xbox)
* **Guard**: Tombol `R1` atau `R2`
* **Assist Striker**: Tombol `L1`
* **Leader Swap**: Tombol `L2`
* **Lock-On Toggle**: Tekan jempol kanan (Thumbstick R3)
* **Movement**: Thumbstick Kiri (L3)

---

### ⚡ Mode Performa (Low-GFX / 60FPS)
* Tombol **`⚡ GFX: HIGH / LOW`** di pojok kanan atas layar.
* Menyalakan mode ini akan mematikan efek bloom, sunrays, dan bayangan berat sehingga perangkat mobile low-end & laptop kentang tetap mendapatkan **60 FPS stabil**.
