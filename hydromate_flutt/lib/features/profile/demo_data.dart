import 'dart:math' as math;

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../reminder/reminder_planner.dart';

// Jadwal kuliah contoh (dipakai bila jadwal masih kosong)
const _jadwalDemo = [
  ClassSchedule(
    nama: 'Kalkulus',
    hari: 1,
    jamMulai: 8 * 60,
    jamSelesai: 9 * 60 + 40,
  ),
  ClassSchedule(
    nama: 'Pemrograman Mobile',
    hari: 1,
    jamMulai: 10 * 60,
    jamSelesai: 11 * 60 + 40,
  ),
  ClassSchedule(
    nama: 'Basis Data',
    hari: 2,
    jamMulai: 14 * 60,
    jamSelesai: 15 * 60 + 40,
  ),
  ClassSchedule(
    nama: 'Struktur Data',
    hari: 3,
    jamMulai: 8 * 60,
    jamSelesai: 9 * 60 + 40,
  ),
  ClassSchedule(
    nama: 'Statistika',
    hari: 4,
    jamMulai: 14 * 60,
    jamSelesai: 15 * 60 + 40,
  ),
  ClassSchedule(
    nama: 'Jaringan Komputer',
    hari: 5,
    jamMulai: 9 * 60,
    jamSelesai: 10 * 60 + 40,
  ),
];

// Slot yang sengaja "diabaikan" agar pengingat adaptif terlihat saat demo
const _slotDiabaikanDemo = {13 * 60, 16 * 60};

// Isi riwayat minum 4 minggu terakhir (tanpa hari ini) agar grafik, streak,
// dan pengingat adaptif langsung terlihat saat presentasi
void isiDataDemo(AppState state, {DateTime? sekarang}) {
  final acak = math.Random(42);
  final hariIni = tanggalSaja(sekarang ?? DateTime.now());

  if (state.schedules.isEmpty) {
    for (final j in _jadwalDemo) {
      state.addSchedule(j);
    }
  }

  final logs = <DrinkLog>[];
  for (var mundur = 28; mundur >= 1; mundur--) {
    final tgl = DateTime(hariIni.year, hariIni.month, hariIni.day - mundur);
    // Umumnya rajin; 6 hari lalu bolong agar grafik bervariasi (streak 5)
    final peluang = mundur == 6 ? 0.4 : 0.92;
    final slot = rencanaPengingat(
      tgl.weekday,
      profil: state.profile,
      jadwal: state.schedules,
      logs: const [],
      adaptif: false,
    );

    for (final s in slot) {
      if (_slotDiabaikanDemo.contains(s)) continue;
      if (acak.nextDouble() > peluang) continue;
      final menit = s + acak.nextInt(20);
      // Pagi kadang kopi, sore kadang teh atau boba
      final jenis = switch (acak.nextInt(10)) {
        0 when s < 12 * 60 => 'Kopi',
        1 => 'Teh',
        2 when s >= 15 * 60 => 'Boba',
        _ => 'Air putih',
      };
      logs.add(
        DrinkLog(
          jenis: jenis,
          ml: 200 + acak.nextInt(4) * 50,
          waktu: DateTime(
            tgl.year,
            tgl.month,
            tgl.day,
            menit ~/ 60,
            menit % 60,
          ),
        ),
      );
    }
  }
  state.addLogs(logs);
}
