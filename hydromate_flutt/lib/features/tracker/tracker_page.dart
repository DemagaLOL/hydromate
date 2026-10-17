import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import 'drink_style.dart';
import 'drink_volume_sheet.dart';
import 'weather_service.dart';

// Halaman Beranda: progres minum hari ini, tambah minum, dan riwayat
class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  double? _suhu;

  @override
  void initState() {
    super.initState();
    _muatCuaca();
  }

  // Ambil suhu lalu hitung ulang target (+300 ml bila >= 30°C)
  Future<void> _muatCuaca() async {
    final suhu = await ambilSuhuSekarang();
    if (!mounted || suhu == null) return;
    setState(() => _suhu = suhu);
    final state = context.read<AppState>();
    final profil = state.profile;
    if (profil != null) {
      state.setTarget(hitungTargetHarian(profil, suhuC: suhu));
    }
  }

  Future<void> _tambah(String jenis) async {
    final ml = await showDrinkVolumeSheet(context, jenis);
    if (ml == null || !mounted) return;
    final log = DrinkLog(jenis: jenis, ml: ml, waktu: DateTime.now());
    context.read<AppState>().addLog(log);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Tercatat $ml ml $jenis (≈ ${formatRibuan(log.mlEfektif)} ml efektif)',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final logsHariIni = state.logsHariIni.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(suhu: _suhu),
        const SizedBox(height: 16),
        _KartuProgres(
          efektif: state.airEfektifHariIni,
          target: state.targetMl,
          streak: state.streakHari,
        ),
        const SizedBox(height: 24),
        Text('Tambah minum', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in koefisienHidrasi.entries)
              ActionChip(
                avatar: Icon(ikonDari(e.key), color: warnaDari(e.key)),
                label: Text('${e.key} ×${e.value}'),
                onPressed: () => _tambah(e.key),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Riwayat hari ini', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (logsHariIni.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Belum ada catatan. Yuk minum segelas air!'),
            ),
          )
        else
          for (final l in logsHariIni)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: warnaDari(l.jenis).withValues(alpha: 0.15),
                  child: Icon(ikonDari(l.jenis), color: warnaDari(l.jenis)),
                ),
                title: Text(l.jenis),
                subtitle: Text(
                  '${formatRibuan(l.ml)} ml → ${formatRibuan(l.mlEfektif)} ml efektif',
                ),
                trailing: Text(formatJam(l.waktu)),
              ),
            ),
      ],
    );
  }
}

// Sapaan dan chip cuaca (tidak tampil bila cuaca gagal dimuat)
class _Header extends StatelessWidget {
  final double? suhu;

  const _Header({required this.suhu});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = suhu;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo!',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Ayo penuhi target minummu hari ini',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (t != null)
          Chip(
            avatar: Icon(t >= 30 ? Icons.wb_sunny : Icons.cloud, size: 18),
            label: Text(
              t >= 30 ? '${t.round()}°C · +300 ml' : '${t.round()}°C',
            ),
          ),
      ],
    );
  }
}

// Lingkaran progres air efektif dibanding target, plus streak
class _KartuProgres extends StatelessWidget {
  final double efektif;
  final int target;
  final int streak;

  const _KartuProgres({
    required this.efektif,
    required this.target,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fraksi = target <= 0 ? 0.0 : (efektif / target).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: fraksi),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 16,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            scheme.secondary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatRibuan(efektif),
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      Text('/ ${formatRibuan(target)} ml'),
                      const SizedBox(height: 4),
                      Text('estimasi air efektif', style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fraksi >= 1
                  ? 'Target hari ini tercapai!'
                  : '${(fraksi * 100).round()}% dari target',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: const Text('🔥'),
              label: Text(
                streak > 0
                    ? '$streak hari berturut-turut'
                    : 'Mulai streak-mu hari ini',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
