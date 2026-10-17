import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../tracker/history_chart.dart';

// Satu lencana pencapaian
class Lencana {
  final String judul;
  final String syarat;
  final IconData ikon;
  final Color warna;
  final bool terbuka;

  const Lencana({
    required this.judul,
    required this.syarat,
    required this.ikon,
    required this.warna,
    required this.terbuka,
  });
}

// Daftar lencana beserta status terbuka, dihitung dari riwayat lokal
List<Lencana> hitungLencana({
  required List<DrinkLog> logs,
  required int target,
  required int streak,
  DateTime? sekarang,
}) {
  final perHari = totalEfektifPerTanggal(logs);
  final hariTercapai = perHari.values.where((v) => v >= target).length;
  final botol = botolTerhemat(logs);
  final pagi = logs.any((l) => l.waktu.hour < 7);

  return [
    Lencana(
      judul: 'Tetes Pertama',
      syarat: 'Catat minum pertama kali',
      ikon: Icons.water_drop,
      warna: const Color(0xFF35C9D6),
      terbuka: logs.isNotEmpty,
    ),
    Lencana(
      judul: 'Pemanasan',
      syarat: 'Streak 3 hari',
      ikon: Icons.local_fire_department,
      warna: const Color(0xFFFF8A3D),
      terbuka: streak >= 3,
    ),
    Lencana(
      judul: 'Seminggu Penuh',
      syarat: 'Streak 7 hari',
      ikon: Icons.calendar_month,
      warna: const Color(0xFF1E6FE0),
      terbuka: streak >= 7,
    ),
    Lencana(
      judul: 'Hydro Hero',
      syarat: 'Target tercapai 30 hari',
      ikon: Icons.military_tech,
      warna: const Color(0xFFE0A21E),
      terbuka: hariTercapai >= 30,
    ),
    Lencana(
      judul: 'Teman Bumi',
      syarat: 'Hemat 10 botol plastik',
      ikon: Icons.eco,
      warna: const Color(0xFF2EAD6B),
      terbuka: botol >= 10,
    ),
    Lencana(
      judul: 'Bangun Segar',
      syarat: 'Minum sebelum jam 7 pagi',
      ikon: Icons.wb_twilight,
      warna: const Color(0xFFB45FD6),
      terbuka: pagi,
    ),
  ];
}
