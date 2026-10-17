import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../reminder/reminder_service.dart';

// Daftar izin & integrasi. Notifikasi sudah berfungsi; kalender, kesehatan,
// dan lokasi masih di roadmap sehingga ditandai "Segera hadir".
class DaftarIntegrasi extends StatefulWidget {
  const DaftarIntegrasi({super.key});

  @override
  State<DaftarIntegrasi> createState() => _DaftarIntegrasiState();
}

class _DaftarIntegrasiState extends State<DaftarIntegrasi> {
  bool? _notifikasi; // null = belum diminta

  Future<void> _izinkanNotifikasi() async {
    final ok = await ReminderService.mintaIzin();
    if (!mounted) return;
    setState(() => _notifikasi = ok);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Notifikasi belum diizinkan. Bisa diaktifkan lewat '
              'Pengaturan HP › Aplikasi › HydroMate.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KartuIntegrasi(
          ikon: Icons.notifications_active_outlined,
          judul: 'Notifikasi pengingat',
          sumber: 'Pengingat lokal di HP',
          isi:
              'Pengingat minum yang digeser keluar jam kuliah dan senyap '
              'saat sesi fokus.',
          badge: 'Disarankan',
          status: switch (_notifikasi) {
            null => 'Belum diminta',
            true => 'Diizinkan',
            false => 'Ditolak',
          },
          aksi: _notifikasi == true ? null : 'Izinkan notifikasi ›',
          onAksi: _izinkanNotifikasi,
          aktif: _notifikasi == true,
        ),
        const SizedBox(height: 14),
        _KartuIntegrasi(
          ikon: Icons.calendar_month_outlined,
          judul: 'Kalender kuliah',
          sumber: 'Google Calendar',
          isi: 'Cari jeda di antara kelas. Pengingat diam saat jadwalmu sibuk.',
          aksi: 'Segera hadir',
          onAksi: () => segeraHadir(context, 'Integrasi Google Calendar'),
        ),
        const SizedBox(height: 14),
        _KartuIntegrasi(
          ikon: Icons.monitor_heart_outlined,
          judul: 'Kesehatan & aktivitas',
          sumber: 'Health Connect',
          isi:
              'Gunakan ringkasan aktivitas untuk membantu menyesuaikan '
              'estimasi target.',
          aksi: 'Segera hadir',
          onAksi: () => segeraHadir(context, 'Integrasi Health Connect'),
        ),
        const SizedBox(height: 14),
        _KartuIntegrasi(
          ikon: Icons.location_on_outlined,
          judul: 'Lokasi saat digunakan',
          sumber: 'Peta isi ulang & cuaca lokal',
          isi:
              'Cari titik isi ulang terdekat dan konteks cuaca. Tanpa '
              'pelacakan terus-menerus.',
          aksi: 'Segera hadir',
          onAksi: () => segeraHadir(context, 'Izin lokasi'),
        ),
        const SizedBox(height: 16),
        const CatatanKecil(
          'Izin dipilih lewat layanan terkait. Akses bisa dicabut kapan saja '
          'di Pengaturan.',
          ikon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}

class _KartuIntegrasi extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String sumber;
  final String isi;
  final String badge;
  final String status;
  final String? aksi;
  final VoidCallback onAksi;
  final bool aktif;

  const _KartuIntegrasi({
    required this.ikon,
    required this.judul,
    required this.sumber,
    required this.isi,
    this.badge = 'Opsional',
    this.status = 'Belum terhubung',
    required this.aksi,
    required this.onAksi,
    this.aktif = false,
  });

  @override
  Widget build(BuildContext context) {
    final segeraHadir = aksi == 'Segera hadir';
    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IkonKotak(ikon, ukuran: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      sumber,
                      style: const TextStyle(color: AppColors.teksRedup),
                    ),
                  ],
                ),
              ),
              PilLabel(badge, kapital: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(isi, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (aktif)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.sukses,
                ),
              if (aktif) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: aktif ? AppColors.sukses : AppColors.teksRedup,
                    fontWeight: aktif ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (aksi != null)
                TautanTeks(
                  aksi!,
                  onTap: onAksi,
                  warna: segeraHadir ? AppColors.teksRedup : AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
