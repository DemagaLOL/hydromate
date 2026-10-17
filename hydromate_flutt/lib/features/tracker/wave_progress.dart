import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

// Lingkaran berisi air bergelombang setinggi [fraksi] (0..1) dengan persentase
// di tengah. Gelombang dan gelembung beranimasi terus.
class WaveProgress extends StatefulWidget {
  final double fraksi;
  final double ukuran;
  final String keterangan;

  const WaveProgress({
    super.key,
    required this.fraksi,
    this.ukuran = 280,
    this.keterangan = 'dari target harian',
  });

  @override
  State<WaveProgress> createState() => _WaveProgressState();
}

class _WaveProgressState extends State<WaveProgress>
    with SingleTickerProviderStateMixin {
  late final _gerak = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _gerak.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.ukuran;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.fraksi.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, level, _) {
        // Tiap teks putih bila posisinya sudah terendam air, gelap bila belum.
        // Angka persen berada sedikit di atas tengah, keterangan di bawahnya.
        final warnaPersen = level >= 0.6 ? Colors.white : AppColors.teks;
        final warnaKet = level >= 0.45 ? Colors.white : AppColors.teks;
        return Container(
          width: u,
          height: u,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.all(u * 0.03),
          child: AnimatedBuilder(
            animation: _gerak,
            builder: (context, child) => CustomPaint(
              painter: _WavePainter(level: level, fase: _gerak.value),
              child: child,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(level * 100).round()}%',
                    style: TextStyle(
                      fontSize: u * 0.22,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: warnaPersen,
                    ),
                  ),
                  SizedBox(height: u * 0.03),
                  Text(
                    widget.keterangan,
                    style: TextStyle(
                      fontSize: u * 0.055,
                      fontWeight: FontWeight.w700,
                      color: warnaKet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double level;
  final double fase;

  _WavePainter({required this.level, required this.fase});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final pusat = Offset(r, r);
    final lingkaran = Path()
      ..addOval(Rect.fromCircle(center: pusat, radius: r));

    canvas.save();
    canvas.clipPath(lingkaran);
    canvas.drawPaint(Paint()..color = const Color(0xFFE9F5FA));
    // Garis lingkar tipis di dalam (dekorasi seperti di desain)
    canvas.drawCircle(
      pusat,
      r * 0.9,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final w = size.width;
    final h = size.height;
    final y0 = h * (1 - level);
    final amplitudo = level <= 0 || level >= 1 ? 0.0 : h * 0.035;
    final geser = fase * 2 * math.pi;

    // Gelombang belakang (lebih transparan)
    canvas.drawPath(
      _gelombang(w, h, y0 - 4, amplitudo, geser + math.pi),
      Paint()..color = AppColors.secondary.withValues(alpha: 0.35),
    );
    // Gelombang depan bergradien toska -> biru
    canvas.drawPath(
      _gelombang(w, h, y0, amplitudo, geser),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF3DD5D0),
            Color(0xFF1F8FE0),
            AppColors.primary,
          ],
          stops: const [0, 0.25, 0.6],
        ).createShader(Rect.fromLTWH(0, y0 - amplitudo, w, h - y0 + amplitudo)),
    );

    // Gelembung kecil yang naik perlahan
    if (level > 0.15) {
      final gelembung = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (var i = 0; i < 3; i++) {
        final t = (fase + i / 3) % 1;
        final x = w * (0.25 + 0.25 * i) + math.sin(t * 2 * math.pi) * 6;
        final y = h - (h - y0) * t;
        if (y > y0 + 8) canvas.drawCircle(Offset(x, y), 4.0 + i * 2, gelembung);
      }
    }
    canvas.restore();
  }

  Path _gelombang(double w, double h, double y0, double amp, double geser) {
    final path = Path()..moveTo(0, y0);
    for (var x = 0.0; x <= w; x += 2) {
      path.lineTo(x, y0 + math.sin(x / w * 2 * math.pi + geser) * amp);
    }
    return path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.level != level || old.fase != fase;
}
