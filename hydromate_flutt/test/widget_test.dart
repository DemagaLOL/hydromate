import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydromate_flutt/core/models.dart';
import 'package:hydromate_flutt/features/focus/pomodoro_timer.dart';
import 'package:hydromate_flutt/features/tracker/drink_volume_sheet.dart';

void main() {
  test('PomodoroTimer: fokus selesai -> istirahat -> fokus menunggu', () {
    var sekarang = DateTime(2026, 1, 1, 9);
    final fase = <FasePomodoro>[];
    final timer = PomodoroTimer(
      durasiFokus: const Duration(seconds: 25),
      durasiIstirahat: const Duration(seconds: 5),
      jam: () => sekarang,
    )..onFaseBerubah = fase.add;

    timer.mulai();
    sekarang = sekarang.add(const Duration(seconds: 10));
    timer.tick();
    expect(formatSisa(timer.sisa), '00:15');

    // Jeda tidak mengurangi waktu
    timer.jeda();
    sekarang = sekarang.add(const Duration(minutes: 3));
    timer.mulai();
    timer.tick();
    expect(formatSisa(timer.sisa), '00:15');

    // Fokus habis -> istirahat otomatis berjalan
    sekarang = sekarang.add(const Duration(seconds: 15));
    timer.tick();
    expect(timer.fase, FasePomodoro.istirahat);
    expect(timer.sesiSelesai, 1);
    expect(timer.berjalan, isTrue);

    // Istirahat habis -> fokus, berhenti menunggu Mulai
    sekarang = sekarang.add(const Duration(seconds: 5));
    timer.tick();
    expect(timer.fase, FasePomodoro.fokus);
    expect(timer.berjalan, isFalse);
    expect(fase, [FasePomodoro.istirahat, FasePomodoro.fokus]);

    // Melewati sesi fokus tidak menambah hitungan
    timer.lewati();
    expect(timer.sesiSelesai, 1);
    timer.dispose();
  });

  test('hitungStreak menghitung hari berturut-turut', () {
    final hariIni = DateTime(2026, 3, 10, 12);
    DrinkLog air(int hariLalu, int ml) => DrinkLog(
      jenis: 'Air putih',
      ml: ml,
      waktu: hariIni.subtract(Duration(days: hariLalu)),
    );

    // Kemarin & 2 hari lalu tercapai, 3 hari lalu tidak, hari ini belum
    final logs = [air(1, 2000), air(2, 2100), air(3, 500), air(0, 300)];
    expect(hitungStreak(logs, 2000, sekarang: hariIni), 2);

    // Hari ini juga tercapai -> 3
    logs.add(air(0, 1800));
    expect(hitungStreak(logs, 2000, sekarang: hariIni), 3);

    // Kopi dihitung dengan koefisien: 2000 x 0.8 = 1600 < 2000
    final kopi = [DrinkLog(jenis: 'Kopi', ml: 2000, waktu: hariIni)];
    expect(hitungStreak(kopi, 2000, sekarang: hariIni), 0);
  });

  testWidgets('Drag gelas ke atas menambah volume lalu Simpan', (tester) async {
    int? hasil;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  hasil = await showDrinkVolumeSheet(context, 'Kopi'),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsWidgets);

    // Pilihan cepat 500 ml, lalu drag ke atas 48 px (= +200 ml)
    await tester.tap(find.text('500 ml'));
    await tester.pump();
    await tester.drag(find.byKey(const Key('gelas')), const Offset(0, -48));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(hasil, 700);
  });

  // Pastikan toJson/fromJson model bolak-balik tanpa kehilangan data
  test('DrinkLog JSON bolak-balik dan air efektif', () {
    final log = DrinkLog(
      jenis: 'Kopi',
      ml: 200,
      waktu: DateTime(2026, 1, 1, 8),
    );
    final hasil = DrinkLog.fromJson(log.toJson());
    expect(hasil.jenis, 'Kopi');
    expect(hasil.ml, 200);
    expect(hasil.waktu, log.waktu);
    expect(hasil.mlEfektif, 160);
  });

  test('hitungTargetHarian sesuai rumus', () {
    const p = UserProfile(beratKg: 60, usia: 20, aktivitas: Aktivitas.sedang);
    expect(hitungTargetHarian(p), 2280);
    expect(hitungTargetHarian(p, suhuC: 31), 2580);
    expect(hitungTargetHarian(p, suhuC: 29), 2280);

    // Usia > 55: 30 ml/kg
    const lansia = UserProfile(
      beratKg: 60,
      usia: 60,
      aktivitas: Aktivitas.sedang,
    );
    expect(hitungTargetHarian(lansia), 2100);
  });

  test('UserProfile lama tanpa jam bangun/tidur tetap terbaca', () {
    final p = UserProfile.fromJson({
      'beratKg': 55,
      'usia': 21,
      'aktivitas': 'rendah',
    });
    expect(p.jamBangun, 7 * 60);
    expect(p.jamTidur, 22 * 60);
    final p2 = UserProfile.fromJson(p.copyWith(jamBangun: 360).toJson());
    expect(p2.jamBangun, 360);
  });

  test('totalEfektifPerHari urut dari terlama sampai hari ini', () {
    final hariIni = DateTime(2026, 3, 10, 12);
    final logs = [
      DrinkLog(jenis: 'Air putih', ml: 500, waktu: hariIni),
      DrinkLog(jenis: 'Kopi', ml: 200, waktu: DateTime(2026, 3, 8, 9)),
    ];
    expect(totalEfektifPerHari(logs, 3, sekarang: hariIni), [160, 0, 500]);
  });

  test('UserProfile dan ClassSchedule JSON bolak-balik', () {
    const p = UserProfile(beratKg: 60, usia: 20, aktivitas: Aktivitas.sedang);
    final p2 = UserProfile.fromJson(p.toJson());
    expect(p2.beratKg, 60);
    expect(p2.aktivitas, Aktivitas.sedang);

    const j = ClassSchedule(hari: 1, jamMulai: 420, jamSelesai: 520);
    final j2 = ClassSchedule.fromJson(j.toJson());
    expect(j2.hari, 1);
    expect(j2.jamSelesai, 520);
  });
}
