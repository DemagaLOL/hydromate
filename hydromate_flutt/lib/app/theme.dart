import 'package:flutter/material.dart';

// Palet warna HydroMate (mengikuti desain UI)
class AppColors {
  static const primary = Color(0xFF1F66DB);
  static const secondary = Color(0xFF3DD5D0);
  static const background = Color(0xFFF3FAFD);
  static const teks = Color(0xFF13283E);
  static const teksRedup = Color(0xFF5D6F82);
  static const tint = Color(0xFFE6F4FA); // kartu lembut kebiruan
  static const garis = Color(0xFFDCEBF3);
  static const aksen = Color(0xFF1C8FC4); // label kecil kapital
  static const hangat = Color(0xFFFBF0E4); // kartu minuman lain
  static const coklat = Color(0xFF8A5A2B);
  static const sukses = Color(0xFF2EAD6B);

  // Gradien khas HydroMate (ikon, kartu tantangan, isi gelombang)
  static const gradien = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3DD5D0), Color(0xFF1F66DB)],
  );

  static const gradienVertikal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3DD5D0), Color(0xFF1F66DB)],
  );
}

// Radius sudut standar
const double radiusKartu = 22;
const double radiusTombol = 18;

// Tema Material 3 untuk seluruh aplikasi
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.background,
    onSurface: AppColors.teks,
    onSurfaceVariant: AppColors.teksRedup,
    outlineVariant: AppColors.garis,
  );
  final bentukTombol = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusTombol),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Nunito',
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.teks, displayColor: AppColors.teks)
        .copyWith(
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: AppColors.teksRedup,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.teks,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    // Kartu putih datar dengan garis tipis
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusKartu),
        side: const BorderSide(color: AppColors.garis),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: bentukTombol,
        minimumSize: const Size(0, 58),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: bentukTombol,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.garis, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusTombol),
        borderSide: const BorderSide(color: AppColors.garis),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusTombol),
        borderSide: const BorderSide(color: AppColors.garis),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusTombol),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      suffixStyle: const TextStyle(color: AppColors.teksRedup),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: const BorderSide(color: AppColors.garis),
      backgroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.garis,
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusKartu),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.teks,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.garis, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: AppColors.tint,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.teksRedup,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.teksRedup,
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

// Kartu dengan latar gradien HydroMate
class KartuGradien extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradien;

  const KartuGradien({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.gradien = AppColors.gradienVertikal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradien,
        borderRadius: BorderRadius.circular(radiusKartu + 4),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

// Judul bagian halaman dengan tautan opsional di kanan
class JudulBagian extends StatelessWidget {
  final String judul;
  final Widget? aksi;

  const JudulBagian(this.judul, {super.key, this.aksi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          ?aksi,
        ],
      ),
    );
  }
}
