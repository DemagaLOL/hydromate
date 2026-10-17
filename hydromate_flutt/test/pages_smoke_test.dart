import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydromate_flutt/app/home_shell.dart';
import 'package:hydromate_flutt/app/theme.dart';
import 'package:hydromate_flutt/core/app_state.dart';
import 'package:hydromate_flutt/core/models.dart';
import 'package:hydromate_flutt/features/focus/focus_page.dart';
import 'package:hydromate_flutt/features/focus/pomodoro_timer.dart';
import 'package:hydromate_flutt/features/map/map_page.dart';
import 'package:hydromate_flutt/features/profile/demo_data.dart';
import 'package:hydromate_flutt/features/profile/onboarding_page.dart';
import 'package:hydromate_flutt/features/profile/settings_page.dart';
import 'package:hydromate_flutt/features/reminder/schedule_page.dart';
import 'package:hydromate_flutt/features/social/social_page.dart';
import 'package:hydromate_flutt/features/tracker/catat_page.dart';
import 'package:hydromate_flutt/features/tracker/stats_page.dart';
import 'package:hydromate_flutt/features/tracker/tracker_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// Pastikan setiap halaman tampil tanpa error/overflow di layar HP
void main() {
  late AppState state;
  late PomodoroTimer timer;

  // Muat font Nunito asli agar ukuran teks sama seperti di HP
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final w in [400, 600, 700, 800, 900]) {
      final bytes = File('assets/fonts/Nunito-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    state = AppState()
      ..profile = const UserProfile(
        nama: 'Nadia Aulia',
        beratKg: 60,
        usia: 21,
        aktivitas: Aktivitas.sedang,
      )
      ..targetMl = 2280;
    isiDataDemo(state);
    state.addLog(DrinkLog(jenis: 'Kopi', ml: 200, waktu: DateTime.now()));
    timer = PomodoroTimer();
  });

  tearDown(() => timer.dispose());

  Future<void> tampilkan(
    WidgetTester tester,
    Widget halaman, {
    Size ukuran = const Size(390, 844),
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: timer),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: SafeArea(child: halaman)),
        ),
      ),
    );
    // Animasi gelombang berulang terus, jadi pump dengan durasi tetap
    await tester.pump(const Duration(seconds: 2));
  }

  // Gulir daftar utama sampai widget terlihat (ListView membangun malas)
  Future<void> gulirKe(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  final log = DrinkLog(jenis: 'Air putih', ml: 250, waktu: DateTime.now());
  final halaman = <String, Widget Function()>{
    'Beranda': () => const TrackerPage(),
    'Statistik': () => const StatsPage(),
    'Riwayat': () => const RiwayatPage(),
    'Jadwal': () => const SchedulePage(),
    'Fokus': () => const FocusPage(),
    'Teman': () => const SocialPage(),
    'Onboarding': () => const OnboardingPage(),
    'Profil': () => const SettingsPage(),
    'Edit profil': () => const EditProfilPage(),
    'Catat': () => const CatatPage(),
    'Tercatat': () => TercatatPage(log: log),
    'Shell': () => const HomeShell(),
  };

  // HP standar dan HP kecil
  const ukuranLayar = [Size(390, 844), Size(360, 640)];

  for (final e in halaman.entries) {
    for (final ukuran in ukuranLayar) {
      testWidgets('${e.key} tampil tanpa error di $ukuran', (tester) async {
        await tampilkan(tester, e.value(), ukuran: ukuran);
        expect(tester.takeException(), isNull);
        // Gulir sampai bawah untuk memeriksa seluruh isi
        final scroll = find.byType(Scrollable).first;
        await tester.drag(scroll, const Offset(0, -3000));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Onboarding: sambutan -> kebutuhan -> izin', (tester) async {
    await tampilkan(tester, const OnboardingPage());
    await gulirKe(tester, find.text('Mulai kebiasaan baik'));
    await tester.tap(find.text('Mulai kebiasaan baik'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kenali kebutuhanmu'), findsOneWidget);
    expect(find.text('1 dari 2'), findsOneWidget);
  });

  testWidgets('Catat: simpan menambah log dan bisa dibatalkan', (tester) async {
    final awal = state.logs.length;
    await tampilkan(tester, const CatatPage());
    await gulirKe(tester, find.text('500 ml'));
    await tester.tap(find.text('500 ml'));
    await tester.pump(const Duration(milliseconds: 500));
    final simpan = find.text('Simpan 500 ml air putih');
    await gulirKe(tester, simpan);
    await tester.tap(simpan);
    // Frame pertama memulai transisi halaman, berikutnya menyelesaikannya
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.logs.length, awal + 1);
    expect(find.text('Seteguk lebih dekat!'), findsOneWidget);
    final batal = find.text('Batalkan pencatatan');
    await gulirKe(tester, batal);
    await tester.tap(batal);
    await tester.pump(const Duration(seconds: 1));
    expect(state.logs.length, awal);
  });

  testWidgets('Isi ulang: pilih titik menampilkan detail', (tester) async {
    await tampilkan(tester, const MapPage());
    expect(find.text('Isi ulang di sekitarmu'), findsOneWidget);
    // Filter gratis menyembunyikan Kantin Pusat
    await gulirKe(tester, find.widgetWithText(FilterChip, 'Gratis'));
    await tester.tap(find.widgetWithText(FilterChip, 'Gratis'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kantin Pusat'), findsNothing);
    final target = find.text('GOR Soesilo Soedarman');
    await gulirKe(tester, target);
    await tester.tap(target);
    // Tunggu animasi pergantian kartu detail selesai
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Catat isi ulang di sini'), findsOneWidget);
    expect(
      find.text('Refill station · Refill station di pintu masuk'),
      findsOneWidget,
    );
    // Error gambar tile (tanpa internet di test) diabaikan
    tester.takeException();
  });

  testWidgets('Teman: buat grup menampilkan kode', (tester) async {
    await tampilkan(tester, const SocialPage());
    final buat = find.text('Buat grup');
    await gulirKe(tester, buat);
    await tester.tap(buat);
    await tester.pump(const Duration(seconds: 1));
    expect(state.kodeGrup, isNotNull);
    // Tombol berubah menjadi undang/keluar, dan label grup memuat kodenya
    expect(find.text('Undang teman'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Grup ${state.kodeGrup}'), findsOneWidget);
  });
}
