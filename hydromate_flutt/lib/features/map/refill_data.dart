import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/supabase_config.dart';

enum JenisRefill { dispenser, refill, galon }

extension JenisRefillInfo on JenisRefill {
  String get label => switch (this) {
    JenisRefill.dispenser => 'Dispenser',
    JenisRefill.refill => 'Refill station',
    JenisRefill.galon => 'Isi ulang galon',
  };

  IconData get ikon => switch (this) {
    JenisRefill.dispenser => Icons.water_drop,
    JenisRefill.refill => Icons.local_drink,
    JenisRefill.galon => Icons.propane_tank_outlined,
  };

  Color get warna => switch (this) {
    JenisRefill.dispenser => const Color(0xFF1E6FE0),
    JenisRefill.refill => const Color(0xFF35C9D6),
    JenisRefill.galon => const Color(0xFF7A5AF8),
  };
}

// Satu titik isi ulang air minum
class TitikRefill {
  final String nama;
  final String keterangan;
  final JenisRefill jenis;
  final bool gratis;
  final String jamBuka;
  final LatLng posisi;

  const TitikRefill({
    required this.nama,
    required this.keterangan,
    required this.jenis,
    required this.gratis,
    required this.jamBuka,
    required this.posisi,
  });

  factory TitikRefill.dariBaris(Map<String, dynamic> r) => TitikRefill(
    nama: r['nama'] as String,
    keterangan: r['keterangan'] as String? ?? '',
    jenis: JenisRefill.values.byName(r['jenis'] as String),
    gratis: r['gratis'] as bool? ?? true,
    jamBuka: r['jam_buka'] as String? ?? '-',
    posisi: LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble()),
  );
}

// Pusat kampus Unsoed Grendeng, Purwokerto
const pusatKampus = LatLng(-7.4296, 109.2538);

// Data bawaan (koordinat perkiraan; sama dengan seed di supabase/schema.sql)
const titikBawaan = [
  TitikRefill(
    nama: 'Perpustakaan Pusat',
    keterangan: 'Dispenser di lobi lantai 1',
    jenis: JenisRefill.dispenser,
    gratis: true,
    jamBuka: '07.30–20.00',
    posisi: LatLng(-7.4285, 109.2525),
  ),
  TitikRefill(
    nama: 'Gedung Rektorat',
    keterangan: 'Dispenser dekat ruang tunggu layanan',
    jenis: JenisRefill.dispenser,
    gratis: true,
    jamBuka: '07.30–16.00',
    posisi: LatLng(-7.4299, 109.2533),
  ),
  TitikRefill(
    nama: 'Masjid Fatimatuzzahra',
    keterangan: 'Kran air minum di area wudu utara',
    jenis: JenisRefill.refill,
    gratis: true,
    jamBuka: '04.00–21.00',
    posisi: LatLng(-7.4307, 109.2546),
  ),
  TitikRefill(
    nama: 'GOR Soesilo Soedarman',
    keterangan: 'Refill station di pintu masuk',
    jenis: JenisRefill.refill,
    gratis: true,
    jamBuka: '06.00–21.00',
    posisi: LatLng(-7.4318, 109.2522),
  ),
  TitikRefill(
    nama: 'Kantin Pusat',
    keterangan: 'Isi ulang galon, bayar per botol',
    jenis: JenisRefill.galon,
    gratis: false,
    jamBuka: '07.00–17.00',
    posisi: LatLng(-7.4292, 109.2556),
  ),
  TitikRefill(
    nama: 'Gedung PKM',
    keterangan: 'Dispenser sekretariat UKM',
    jenis: JenisRefill.dispenser,
    gratis: true,
    jamBuka: '08.00–21.00',
    posisi: LatLng(-7.4278, 109.2541),
  ),
];

// Ambil titik dari Supabase bila tersedia, selain itu pakai data bawaan
Future<List<TitikRefill>> muatTitikRefill() async {
  if (!SupabaseConfig.aktif) return titikBawaan;
  try {
    final rows = await SupabaseConfig.client.from('titik_refill').select();
    final hasil = rows.map(TitikRefill.dariBaris).toList();
    return hasil.isEmpty ? titikBawaan : hasil;
  } catch (e) {
    debugPrint('Gagal memuat titik refill: $e');
    return titikBawaan;
  }
}
