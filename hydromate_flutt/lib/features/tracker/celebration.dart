import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

// Dialog perayaan saat target harian tercapai, dengan hujan tetes air
Future<void> showCelebration(BuildContext context, {required int streak}) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, _, _) => _Perayaan(streak: streak),
    transitionBuilder: (context, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _Perayaan extends StatefulWidget {
  final int streak;

  const _Perayaan({required this.streak});

  @override
  State<_Perayaan> createState() => _PerayaanState();
}

class _PerayaanState extends State<_Perayaan>
    with SingleTickerProviderStateMixin {
  late final _hujan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  @override
  void dispose() {
    _hujan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _hujan,
              builder: (context, _) =>
                  CustomPaint(painter: _TetesPainter(_hujan.value)),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              color: Colors.transparent,
              child: KartuGradien(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    const Text(
                      'Target tercapai!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.streak > 1
                          ? 'Streak-mu sekarang ${widget.streak} hari berturut-turut 🔥'
                          : 'Tubuhmu terhidrasi dengan baik hari ini 💧',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pengingat hari ini dimatikan otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Mantap!'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Tetes-tetes air yang jatuh dari atas layar
class _TetesPainter extends CustomPainter {
  final double t;

  _TetesPainter(this.t);

  static final _tetes = List.generate(36, (i) {
    final r = math.Random(i * 7 + 3);
    return (
      x: r.nextDouble(),
      tunda: r.nextDouble() * 0.4,
      ukuran: 6 + r.nextDouble() * 8,
      warna: r.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _tetes) {
      final p = ((t - d.tunda) / 0.6).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final pusat = Offset(d.x * size.width, -20 + p * (size.height + 40));
      final warna = (d.warna ? AppColors.secondary : AppColors.primary)
          .withValues(alpha: 1 - p * 0.6);
      final s = d.ukuran;
      final path = Path()
        ..moveTo(pusat.dx, pusat.dy - s * 1.4)
        ..quadraticBezierTo(
          pusat.dx + s,
          pusat.dy,
          pusat.dx,
          pusat.dy + s * 0.6,
        )
        ..quadraticBezierTo(
          pusat.dx - s,
          pusat.dy,
          pusat.dx,
          pusat.dy - s * 1.4,
        );
      canvas.drawPath(path, Paint()..color = warna);
    }
  }

  @override
  bool shouldRepaint(_TetesPainter old) => old.t != t;
}
