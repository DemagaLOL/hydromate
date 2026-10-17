import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/home_shell.dart';
import 'app/theme.dart';
import 'core/app_state.dart';
import 'core/supabase_config.dart';
import 'features/focus/pomodoro_timer.dart';
import 'features/profile/onboarding_page.dart';
import 'features/reminder/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat data tersimpan sebelum aplikasi tampil
  final state = AppState();
  await state.load();

  // Supabase opsional (leaderboard & titik refill); tanpa konfigurasi app
  // tetap berjalan dengan data lokal
  await SupabaseConfig.init();

  // Timer Pomodoro hidup di level aplikasi agar tetap berjalan saat halaman
  // Fokus ditutup
  final timer = PomodoroTimer();

  // Siapkan notifikasi, lalu pengingat otomatis mengikuti perubahan state
  // dan senyap selama sesi fokus
  await ReminderService.init();
  ReminderService.pantau(state);
  ReminderService.pantauFokus(timer);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: timer),
      ],
      child: const HydroMateApp(),
    ),
  );
}

class HydroMateApp extends StatelessWidget {
  const HydroMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Onboarding bila profil belum diisi, selain itu ke HomeShell
    final sudahAdaProfil = context.select<AppState, bool>(
      (s) => s.profile != null,
    );

    return MaterialApp(
      title: 'HydroMate',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Bahasa Indonesia untuk pemilih jam, dialog, dan teks bawaan
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Transisi halus antara onboarding dan halaman utama
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: sudahAdaProfil ? const HomeShell() : const OnboardingPage(),
      ),
    );
  }
}
