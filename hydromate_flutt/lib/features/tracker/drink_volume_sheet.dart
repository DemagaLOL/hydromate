import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import 'drink_style.dart';

// Buka bottom sheet pemilih volume; hasilnya ml yang dipilih atau null bila batal
Future<int?> showDrinkVolumeSheet(BuildContext context, String jenis) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DrinkVolumeSheet(jenis: jenis),
  );
}

class DrinkVolumeSheet extends StatefulWidget {
  final String jenis;

  const DrinkVolumeSheet({super.key, required this.jenis});

  @override
  State<DrinkVolumeSheet> createState() => _DrinkVolumeSheetState();
}

class _DrinkVolumeSheetState extends State<DrinkVolumeSheet> {
  static const _minMl = 50;
  static const _maxMl = 1000;
  static const _langkah = 50;
  static const _lebarGelas = 160.0;
  static const _tinggiGelas = 240.0;
  static const _pilihanCepat = [150, 250, 350, 500];

  int _ml = 250;
  double _mlMentah = 250; // nilai sebelum dibulatkan, untuk drag yang halus

  // Bulatkan ke kelipatan 50, getar halus tiap kali berpindah kelipatan
  void _ubahMl(double mentah) {
    _mlMentah = mentah.clamp(_minMl.toDouble(), _maxMl.toDouble());
    final dibulatkan = ((_mlMentah / _langkah).round() * _langkah).clamp(
      _minMl,
      _maxMl,
    );
    if (dibulatkan != _ml) {
      HapticFeedback.selectionClick();
      setState(() => _ml = dibulatkan);
    }
  }

  // Geser ke atas menambah, ke bawah mengurangi
  void _onDrag(DragUpdateDetails d) =>
      _ubahMl(_mlMentah - d.delta.dy * _maxMl / _tinggiGelas);

  // Tap langsung ke level yang disentuh
  void _onTap(TapDownDetails d) =>
      _ubahMl((1 - d.localPosition.dy / _tinggiGelas) * _maxMl);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final warna = warnaDari(widget.jenis);
    final efektif = _ml * (koefisienHidrasi[widget.jenis] ?? 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tambah ${widget.jenis}', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Geser gelas ke atas atau ke bawah',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              key: const Key('gelas'),
              dragStartBehavior: DragStartBehavior.down,
              onVerticalDragStart: (_) => _mlMentah = _ml.toDouble(),
              onVerticalDragUpdate: _onDrag,
              onTapDown: _onTap,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _ml / _maxMl),
                duration: const Duration(milliseconds: 150),
                builder: (context, fraksi, _) => CustomPaint(
                  size: const Size(_lebarGelas, _tinggiGelas),
                  painter: _GelasPainter(
                    fraksi: fraksi,
                    warnaCairan: warna,
                    warnaGaris: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${formatRibuan(_ml)} ml',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: warna,
              ),
            ),
            Text(
              '≈ ${formatRibuan(efektif)} ml air efektif (estimasi)',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final v in _pilihanCepat)
                  ChoiceChip(
                    label: Text('$v ml'),
                    selected: _ml == v,
                    onSelected: (_) => _ubahMl(v.toDouble()),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _ml),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Simpan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gelas berbentuk trapesium dengan cairan bergelombang setinggi fraksi (0..1)
class _GelasPainter extends CustomPainter {
  final double fraksi;
  final Color warnaCairan;
  final Color warnaGaris;

  _GelasPainter({
    required this.fraksi,
    required this.warnaCairan,
    required this.warnaGaris,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gelas = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.15, h)
      ..close();

    // Cairan dipotong mengikuti bentuk gelas
    canvas.save();
    canvas.clipPath(gelas);
    canvas.drawPath(
      gelas,
      Paint()..color = warnaCairan.withValues(alpha: 0.08),
    );
    final level = h * (1 - fraksi);
    final cairan = Path()..moveTo(0, level);
    for (var x = 0.0; x <= w; x += 4) {
      cairan.lineTo(x, level + math.sin(x / w * 2 * math.pi) * 4);
    }
    cairan
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      cairan,
      Paint()..color = warnaCairan.withValues(alpha: 0.85),
    );
    canvas.restore();

    // Garis skala tiap 250 ml
    final skala = Paint()
      ..color = warnaGaris.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      final y = h * (1 - i / 4);
      final kanan = w - (w * 0.15) * (y / h);
      canvas.drawLine(Offset(kanan - 20, y), Offset(kanan - 4, y), skala);
    }

    // Garis tepi gelas
    canvas.drawPath(
      gelas,
      Paint()
        ..color = warnaGaris.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GelasPainter old) =>
      old.fraksi != fraksi ||
      old.warnaCairan != warnaCairan ||
      old.warnaGaris != warnaGaris;
}
