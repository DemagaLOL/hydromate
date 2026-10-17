import 'package:flutter_test/flutter_test.dart';
import 'package:hydromate_flutt/core/models.dart';
import 'package:hydromate_flutt/features/reminder/reminder_planner.dart';

int jam(int j, [int m = 0]) => j * 60 + m;

void main() {
  test('tanpa jadwal: tiap jam 07.00 sampai 21.00', () {
    final hasil = hitungWaktuPengingat(1, []);
    expect(hasil, [for (var j = 7; j <= 21; j++) jam(j)]);
  });

  test('kelas 08.00-10.00: pengingat 07.50 lalu digeser ke 10.00', () {
    final jadwal = [
      ClassSchedule(hari: 1, jamMulai: jam(8), jamSelesai: jam(10)),
    ];
    final hasil = hitungWaktuPengingat(1, jadwal);
    expect(hasil.take(4), [jam(7), jam(7, 50), jam(10), jam(11)]);
    // Tidak ada pengingat di dalam jam kuliah
    expect(hasil.where((m) => m > jam(8) && m < jam(10)), isEmpty);
  });

  test('jadwal hari lain tidak berpengaruh', () {
    final jadwal = [
      ClassSchedule(hari: 2, jamMulai: jam(8), jamSelesai: jam(10)),
    ];
    expect(hitungWaktuPengingat(1, jadwal), hitungWaktuPengingat(1, []));
  });

  test('kelas berurutan: digeser sampai kelas terakhir selesai', () {
    final jadwal = [
      ClassSchedule(hari: 3, jamMulai: jam(8), jamSelesai: jam(9, 40)),
      ClassSchedule(hari: 3, jamMulai: jam(9, 40), jamSelesai: jam(11, 20)),
    ];
    final hasil = hitungWaktuPengingat(3, jadwal);
    expect(hasil.where((m) => m > jam(8) && m < jam(11, 20)), isEmpty);
    expect(hasil, contains(jam(11, 20)));
    expect(hasil, contains(jam(7, 50)));
  });

  test('kelas sampai malam: tidak ada pengingat setelah 21.00', () {
    final jadwal = [
      ClassSchedule(hari: 4, jamMulai: jam(19), jamSelesai: jam(21, 30)),
    ];
    final hasil = hitungWaktuPengingat(4, jadwal);
    expect(hasil.last, jam(18, 50));
    expect(hasil.every((m) => m <= jam(21)), isTrue);
  });

  test('jendela kustom mengikuti jam bangun dan tidur', () {
    final hasil = hitungWaktuPengingat(1, [], awal: jam(9), akhir: jam(12));
    expect(hasil, [jam(9), jam(10), jam(11), jam(12)]);
  });

  test('slot diabaikan dimundurkan 30 menit', () {
    final hasil = hitungWaktuPengingat(
      1,
      [],
      awal: jam(9),
      akhir: jam(12),
      diabaikan: {jam(10)},
    );
    expect(hasil, [jam(9), jam(10, 30), jam(11), jam(12)]);
  });

  group('slotDiabaikan', () {
    // Rabu, 4 Maret 2026 -> Senin sebelumnya 2, lalu 23 & 16 & 9 Feb
    final sekarang = DateTime(2026, 3, 4, 12);
    final senin = [
      DateTime(2026, 3, 2),
      DateTime(2026, 2, 23),
      DateTime(2026, 2, 16),
      DateTime(2026, 2, 9),
    ];
    DrinkLog minum(DateTime tgl, int menit) => DrinkLog(
      jenis: 'Air putih',
      ml: 250,
      waktu: tgl.add(Duration(minutes: menit)),
    );

    test('3 dari 4 minggu tidak direspons -> diabaikan', () {
      final logs = [
        for (final t in senin) minum(t, jam(9, 10)), // slot 09.00 direspons
        minum(senin[0], jam(10, 20)), // slot 10.00 hanya direspons sekali
      ];
      final hasil = slotDiabaikan(
        1,
        [],
        logs,
        awal: jam(9),
        akhir: jam(10),
        sekarang: sekarang,
      );
      expect(hasil, {jam(10)});
    });

    test('hari tanpa catatan sama sekali tidak dihitung', () {
      // Hanya 2 Senin yang dipakai, keduanya tanpa respons slot 10.00
      final logs = [minum(senin[0], jam(9)), minum(senin[1], jam(9))];
      final hasil = slotDiabaikan(
        1,
        [],
        logs,
        awal: jam(9),
        akhir: jam(10),
        sekarang: sekarang,
      );
      expect(hasil, isEmpty);
    });

    test('slot di dalam jam kuliah tidak dinilai', () {
      final logs = [for (final t in senin) minum(t, jam(7))];
      final jadwal = [
        ClassSchedule(hari: 1, jamMulai: jam(8), jamSelesai: jam(12)),
      ];
      final hasil = slotDiabaikan(
        1,
        jadwal,
        logs,
        awal: jam(9),
        akhir: jam(11),
        sekarang: sekarang,
      );
      expect(hasil, isEmpty);
    });
  });

  test('jarak antar pengingat minimal 30 menit', () {
    final jadwal = [
      ClassSchedule(hari: 5, jamMulai: jam(8, 30), jamSelesai: jam(9, 50)),
      ClassSchedule(hari: 5, jamMulai: jam(13), jamSelesai: jam(14, 40)),
    ];
    final hasil = hitungWaktuPengingat(5, jadwal);
    for (var i = 1; i < hasil.length; i++) {
      expect(hasil[i] - hasil[i - 1], greaterThanOrEqualTo(30));
    }
  });
}
