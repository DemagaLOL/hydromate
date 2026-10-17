# HydroMate - Konteks Proyek
Aplikasi pengingat minum air putih yang adaptif terhadap jadwal pengguna.
Dibuat untuk hackathon 1 hari (13 jam). Target: demo mulus di HP Android, bukan produk lengkap.

## Stack (WAJIB, jangan menyarankan alternatif)
- Flutter (Dart), target Android saja
- State: provider (ChangeNotifier) di lib/core/app_state.dart
- Penyimpanan lokal: shared_preferences (data disimpan sebagai JSON)
- Notifikasi: flutter_local_notifications + timezone (lokal saja)
- Peta: flutter_map + latlong2 + tile OpenStreetMap (tanpa API key)
- Cuaca: Open-Meteo via package http (tanpa API key)
- Tanpa backend dan tanpa database server. Semua data lokal di HP.

## Aturan
1. Jangan tambah package tanpa izin. Jangan sarankan state management lain (bukan Riverpod/Bloc/GetX).
2. Jangan edit folder android/ atau ios/ kecuali diminta ketua (A).
3. Hanya ketua (A) yang mengedit lib/main.dart dan lib/app/.
4. Setiap anggota hanya mengedit foldernya sendiri di lib/features/<nama>/.
5. Setiap fitur mengekspor satu widget halaman/komponen utama, tanpa mengubah navigasi.
6. Gunakan Material 3, null safety, dan widget const bila memungkinkan.
7. Beri komentar singkat dalam Bahasa Indonesia. Jangan ubah file di luar tugas.
8. Gunakan API terbaru package (cek contoh resmi di pub.dev bila ragu), jangan kode versi lama.

## Struktur
lib/main.dart
lib/app/ (theme.dart, home_shell.dart: bottom navigation 4 tab)
lib/core/ (models.dart, app_state.dart)
lib/features/ profile, tracker, reminder, focus, social, map

## Warna
Primary #1E6FE0, Secondary #35C9D6, Background #F5F9FF, Teks #12263F

## Fitur (versi hackathon)
1. Smart Schedule Sync: pengguna input jadwal kuliah manual, pengingat digeser keluar jam kuliah
2. Beverage Balancer: koefisien hidrasi per minuman (Air putih 1.0, Teh 0.9, Kopi 0.8, Boba 0.7, Energi 0.6), ditampilkan sebagai "estimasi"
3. Focus Session: Pomodoro 25/5 menit, saat jeda muncul prompt minum
4. Streak + Leaderboard: streak lokal, leaderboard data dummy
5. Refill Map: flutter_map, titik refill hardcode area kampus Unsoed Purwokerto
Target harian = berat x 33 ml + bonus aktivitas (sedang +300, tinggi +600) + bonus suhu >=30C (+300)
