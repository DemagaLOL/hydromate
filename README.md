# 💧 HydroMate

**Pengingat minum air yang menyesuaikan diri dengan jadwal kuliahmu.**

HydroMate adalah aplikasi Android untuk mahasiswa. Pengingat minumnya otomatis menghindari jam kuliah, minuman selain air putih dihitung secara adil, dan kebiasaan minum diselipkan ke sesi belajar. Mencari tempat isi ulang botol di kampus juga jadi lebih mudah.

---

## 1. Nama Tim dan Daftar Anggota

**Nama tim:** [Nama Tim]

| No | Nama | Peran |
|----|------|-------|
| 1  | Danawendra Girinandana | Ketua |
| 2  | Raflyanno Kautsar Wibowo | Anggota |
| 3  | Noval Rangga Nandika | Anggota |
| 4  | Devania Dwi Cantika | Anggota |
| 5  | Pradipta Bayuaji | Anggota |

---

## 2. Deskripsi Permasalahan

Mahasiswa sering lupa minum karena hari mereka padat: kuliah berjam-jam, tugas dan sesi belajar panjang di depan laptop. Aplikasi pengingat minum yang ada umumnya kurang cocok untuk keseharian mahasiswa:

- **Pengingatnya kaku.** Notifikasi muncul tiap jam, bahkan saat sedang presentasi atau di tengah kelas. Akhirnya notifikasi diabaikan atau dimatikan.
- **Semua minuman dianggap sama.** Kopi, teh, boba dan minuman energi tidak menghidrasi sebaik air putih, tapi dihitung setara.
- **Target harian disamaratakan.** "8 gelas sehari" tidak memperhitungkan berat badan, aktivitas, dan cuaca panas.
- **Lupa minum saat fokus belajar.** Berjam-jam di depan laptop tanpa jeda, tanpa minum, tanpa bergerak.
- **Sulit mencari tempat isi ulang air** di kampus, sehingga mahasiswa membeli air kemasan sekali pakai.

---

## 3. Solusi yang Dikembangkan

HydroMate menggabungkan pencatatan minum, pengingat cerdas dan motivasi sosial dalam satu aplikasi.

| Fitur | Cara kerja |
|-------|------------|
| 🗓️ **Smart Schedule Sync** | Pengguna memasukkan jadwal kuliah. Pengingat minum otomatis digeser keluar jam kelas, dan ada pengingat "minum dulu" 10 menit sebelum kelas dimulai. Slot pengingat yang sering diabaikan dipindah ke waktu lain (adaptif). |
| 🥤 **Beverage Balancer** | Setiap minuman punya koefisien hidrasi (estimasi): Air putih 1.0, Teh 0.9, Kopi 0.8, Boba 0.7, Energi 0.6. Progres harian dihitung dari **air efektif**: 200 ml kopi = 160 ml air efektif. |
| 🎯 **Target personal** | Target harian = berat × 33 ml (× 30 ml bila usia > 55) + bonus aktivitas (sedang +300 ml, tinggi +600 ml) + **bonus cuaca** +300 ml bila suhu Purwokerto ≥ 30 °C (data langsung dari Open-Meteo). |
| ⏱️ **Focus Session** | Timer Pomodoro 25 menit fokus / 5 menit istirahat. Saat istirahat, aplikasi mengajak pengguna **berdiri, meregangkan otot, dan minum air**, dan minumnya bisa langsung dicatat. Pengingat biasa disenyapkan selama sesi fokus. |
| 🔥 **Streak & Teman** | Streak hari berturut-turut target tercapai, lencana pencapaian, tantangan kampus 7 hari, dan leaderboard bersama teman lewat kode grup. |
| 📍 **Peta Isi Ulang** | Peta titik isi ulang air minum di kampus Unsoed Grendeng, Purwokerto. Minum bisa langsung dicatat dari titik isi ulang. |
| 📊 **Statistik** | Grafik harian/mingguan, estimasi jumlah botol plastik yang berhasil dihemat, dan riwayat minum yang bisa dihapus dengan digeser. |

**Alur penggunaan singkat:**
1. **Onboarding:** isi nama, usia, berat, aktivitas, dan jam bangun/tidur. Target harian langsung dihitung.
2. **Beranda:** lihat progres air hari ini dan pengingat berikutnya, lalu catat minum dengan sekali ketuk.
3. Tambahkan **jadwal kuliah**. Pengingat otomatis menyesuaikan.
4. Mulai **sesi fokus** saat belajar, lalu ikuti ajakan minum di setiap istirahat.
5. Pantau **statistik**, bersaing di **leaderboard**, dan cari **titik isi ulang** di peta.

> 💡 **Untuk demo:** buka **Profil & pengaturan → Privasi & data pribadi** lalu pilih *Isi data demo*. Riwayat 4 minggu dan jadwal kuliah contoh akan terisi, sehingga grafik, streak dan pengingat adaptif langsung terlihat.

**Privasi:** profil, riwayat minum dan jadwal hanya disimpan di HP pengguna. Yang dikirim ke server hanya nama panggilan dan statistik untuk leaderboard, dan itu pun hanya bila Supabase diaktifkan.

---

## 4. Teknologi yang Digunakan

| Kategori | Teknologi |
|----------|-----------|
| Bahasa | Dart 3 |
| Framework | Flutter (Material 3), target **Android** |
| State management | `provider` (ChangeNotifier) |
| Penyimpanan lokal | `shared_preferences` (data disimpan sebagai JSON di HP) |
| Notifikasi | `flutter_local_notifications` + `timezone` (notifikasi lokal terjadwal) |
| Peta | `flutter_map` + tile **OpenStreetMap** (tanpa API key) |
| Cuaca | API **Open-Meteo** via `http` (tanpa API key) |
| Database online *(opsional)* | **Supabase** (`supabase_flutter`): leaderboard realtime dan data titik isi ulang, login anonim |
| Font | Nunito (lisensi OFL) |

**Struktur folder:**

```
hydromate/
├── PROJECT_CONTEXT.md          # konteks & aturan proyek
└── hydromate_flutt/            # proyek Flutter
    ├── lib/
    │   ├── main.dart           # titik masuk aplikasi
    │   ├── app/                # tema, navigasi (HomeShell), komponen UI bersama
    │   ├── core/               # model data, AppState, konfigurasi Supabase
    │   └── features/
    │       ├── profile/        # onboarding, profil & pengaturan, data demo
    │       ├── tracker/        # beranda, catat minum, statistik, cuaca
    │       ├── reminder/       # jadwal kuliah & penjadwal pengingat
    │       ├── focus/          # timer Pomodoro & panduan istirahat
    │       ├── social/         # streak, lencana, leaderboard
    │       └── map/            # peta titik isi ulang
    ├── supabase/schema.sql     # skema database (opsional)
    └── test/                   # unit & widget test
```

---

## 5. Petunjuk Instalasi dan Cara Menjalankan Aplikasi

### Prasyarat
- [**Flutter SDK**](https://docs.flutter.dev/get-started/install) versi stabil terbaru (Dart ≥ 3.13)
- [**Android Studio**](https://developer.android.com/studio) (untuk Android SDK dan emulator)
- **Git**
- HP Android dengan *USB debugging* aktif, **atau** emulator Android

Cek kesiapan dengan:
```bash
flutter doctor
```
Pastikan baris **Flutter** dan **Android toolchain** bertanda ✓. Jika diminta, jalankan `flutter doctor --android-licenses` lalu setujui semua lisensi.

### Langkah 1: Clone repository
```bash
git clone https://github.com/DemagaLOL/hydromate.git
cd hydromate/hydromate_flutt
```

### Langkah 2: Install dependency
```bash
flutter pub get
```

### Langkah 3: Siapkan perangkat
- **HP Android:** aktifkan *Opsi Pengembang* (ketuk *Nomor Build* 7 kali di Pengaturan → Tentang ponsel), nyalakan **USB debugging**, lalu sambungkan HP dengan kabel USB.
- **Emulator:** buka Android Studio → *Device Manager* → buat dan jalankan perangkat virtual.

Pastikan perangkat terdeteksi:
```bash
flutter devices
```

### Langkah 4: Jalankan aplikasi
```bash
flutter run
```
Aplikasi akan ter-install dan terbuka di HP/emulator. Saat pertama kali dibuka, isi data diri di halaman onboarding dan izinkan notifikasi.

> Ingin melihat tampilan tanpa HP? Jalankan `flutter run -d chrome`. Fitur notifikasi hanya berfungsi di Android.

### (Opsional) Mengaktifkan leaderboard online dengan Supabase
Tanpa langkah ini aplikasi **tetap berjalan normal**: leaderboard memakai data contoh dan peta memakai titik isi ulang bawaan.

1. Buat proyek baru di [supabase.com](https://supabase.com).
2. Buka **SQL Editor**, lalu jalankan seluruh isi [`hydromate_flutt/supabase/schema.sql`](hydromate_flutt/supabase/schema.sql).
3. Buka **Authentication → Sign In / Providers**, lalu aktifkan **Allow anonymous sign-ins**.
4. Salin **Project URL** dan **publishable/anon key** dari *Project Settings → API*, lalu jalankan:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_KEY=<publishable-key>
   ```

### Membuat file APK
```bash
flutter build apk --release
```
File APK ada di `build/app/outputs/flutter-apk/app-release.apk` dan bisa langsung dipasang di HP Android.

### Menjalankan pengujian
```bash
flutter analyze
flutter test
```

### Kendala umum
| Masalah | Solusi |
|---------|--------|
| `flutter` tidak dikenali | Tambahkan folder `flutter/bin` ke PATH, lalu buka ulang terminal. |
| `No Android SDK found` | Install Android Studio, buka sekali agar SDK terpasang, lalu jalankan `flutter doctor`. |
| HP tidak muncul di `flutter devices` | Cek kabel data, izinkan *USB debugging* di pop-up HP, atau coba mode transfer file (MTP). |
| Notifikasi tidak muncul | Izinkan notifikasi untuk HydroMate di Pengaturan HP, dan matikan penghemat baterai untuk aplikasi ini. |
