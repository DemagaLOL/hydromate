import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/home_shell.dart';
import 'app/theme.dart';
import 'core/app_state.dart';
import 'features/profile/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat data tersimpan sebelum aplikasi tampil
  final state = AppState();
  await state.load();

  runApp(
    ChangeNotifierProvider.value(value: state, child: const HydroMateApp()),
  );
}

class HydroMateApp extends StatelessWidget {
  const HydroMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Onboarding bila profil belum diisi, selain itu ke HomeShell
    final sudahAdaProfil =
        context.select<AppState, bool>((s) => s.profile != null);

    return MaterialApp(
      title: 'HydroMate',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: sudahAdaProfil ? const HomeShell() : const OnboardingPage(),
    );
  }
}
