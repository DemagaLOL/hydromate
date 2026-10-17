import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import 'drink_style.dart';

// Grafik batang bergaya pil: lintasan lembut, isi gradien, angka di atas batang.
// Batang [sorot] (mis. hari ini) diberi warna solid dan label tebal.
class GrafikBatang extends StatelessWidget {
  final List<double> nilai;
  final List<String> label;
  final double maks;
  final int? sorot;
  final double tinggi;

  const GrafikBatang({
    super.key,
    required this.nilai,
    required this.label,
    required this.maks,
    this.sorot,
    this.tinggi = 160,
  });

  // Angka ringkas di atas batang: 1.600, 950, atau "–" bila kosong
  static String _angka(double v) => v <= 0 ? '–' : formatRibuan(v);

  @override
  Widget build(BuildContext context) {
    final skala = maks <= 0 ? 1.0 : maks;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < nilai.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      _angka(nilai[i]),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: i == sorot
                            ? AppColors.primary
                            : AppColors.teksRedup,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: tinggi,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (nilai[i] / skala).clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => FractionallySizedBox(
                        heightFactor: v,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: i == sorot
                                ? null
                                : AppColors.gradienVertikal,
                            color: i == sorot ? AppColors.primary : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: Text(
                      label[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: i == sorot
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: i == sorot
                            ? AppColors.primary
                            : AppColors.teksRedup,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Estimasi botol plastik 600 ml yang tidak terpakai karena air putih
// diminum dari tumbler/refill
int botolTerhemat(List<DrinkLog> logs) {
  final mlAir = logs
      .where((l) => l.jenis == 'Air putih')
      .fold(0, (total, l) => total + l.ml);
  return mlAir ~/ 600;
}
