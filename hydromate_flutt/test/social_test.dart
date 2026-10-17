import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hydromate_flutt/core/models.dart';
import 'package:hydromate_flutt/features/social/badges.dart';
import 'package:hydromate_flutt/features/social/social_service.dart';

void main() {
  test('peringkat: persen hari ini (maks 100), lalu streak, lalu ml', () {
    EntriPeringkat e(String n, int s, int p, int ml) => EntriPeringkat(
      id: n,
      nama: n,
      streak: s,
      persenHariIni: p,
      mlMingguIni: ml,
    );
    final hasil = urutkanPeringkat([
      e('A', 3, 50, 100),
      e('B', 5, 10, 100),
      e('C', 3, 80, 100),
      e('D', 3, 80, 900),
    ]);
    expect(hasil.map((x) => x.nama), ['D', 'C', 'A', 'B']);
  });

  test('kode grup acak selalu valid', () {
    final acak = math.Random(1);
    for (var i = 0; i < 100; i++) {
      expect(kodeGrupValid(buatKodeGrup(acak)), isTrue);
    }
    expect(kodeGrupValid('abc123'), isFalse);
    expect(kodeGrupValid('ABC12'), isFalse);
  });

  test('lencana terbuka sesuai riwayat', () {
    final hariIni = DateTime(2026, 3, 10, 6, 30);
    final logs = [DrinkLog(jenis: 'Air putih', ml: 2400, waktu: hariIni)];
    final l = {
      for (final x in hitungLencana(logs: logs, target: 2000, streak: 3))
        x.judul: x.terbuka,
    };
    expect(l['Tetes Pertama'], isTrue);
    expect(l['Pemanasan'], isTrue);
    expect(l['Seminggu Penuh'], isFalse);
    expect(l['Bangun Segar'], isTrue); // minum sebelum jam 7
    expect(l['Teman Bumi'], isFalse); // 2400 ml = 4 botol
  });
}
