import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'break_sheet.dart';
import 'pomodoro_timer.dart';

// Halaman Fokus: Pomodoro 25/5 dengan panduan istirahat minum & peregangan
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  final _timer = PomodoroTimer();
  bool _modeDemo = false;

  @override
  void initState() {
    super.initState();
    _timer.onFaseBerubah = _saatFaseBerubah;
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _saatFaseBerubah(FasePomodoro fase) {
    if (!mounted) return;
    HapticFeedback.vibrate();
    if (fase == FasePomodoro.istirahat) {
      // Dorong pengguna berdiri, meregangkan otot, dan minum
      showBreakSheet(context, _timer);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Istirahat selesai. Tekan Mulai untuk sesi berikutnya.'),
        ));
    }
  }

  // Jumlah ikon terisi dalam satu putaran 4 sesi (1..4, atau 0 bila belum ada)
  int _ikonTerisi(int sesi) => sesi == 0 ? 0 : (sesi - 1) % 4 + 1;

  void _gantiMode(bool demo) {
    setState(() => _modeDemo = demo);
    if (demo) {
      _timer.aturDurasi(const Duration(seconds: 25), const Duration(seconds: 5));
    } else {
      _timer.aturDurasi(const Duration(minutes: 25), const Duration(minutes: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _timer,
      builder: (context, _) {
        final fokus = _timer.fase == FasePomodoro.fokus;
        final warna = fokus ? scheme.primary : scheme.secondary;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Sesi Fokus',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Fokus 25 menit, lalu istirahat 5 menit untuk minum'),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('25 / 5 menit')),
                  ButtonSegment(value: true, label: Text('Demo 25 / 5 detik')),
                ],
                selected: {_modeDemo},
                onSelectionChanged:
                    _timer.berjalan ? null : (s) => _gantiMode(s.first),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _timer.progres,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        color: warna,
                        backgroundColor: warna.withValues(alpha: 0.15),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fokus ? Icons.menu_book : Icons.local_drink,
                          color: warna,
                        ),
                        Text(
                          fokus ? 'Fokus' : 'Istirahat',
                          style: textTheme.titleMedium?.copyWith(color: warna),
                        ),
                        Text(
                          formatSisa(_timer.sisa),
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  tooltip: 'Ulang',
                  onPressed: _timer.ulang,
                  icon: const Icon(Icons.restart_alt),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _timer.berjalan ? _timer.jeda : _timer.mulai,
                  icon: Icon(_timer.berjalan ? Icons.pause : Icons.play_arrow),
                  label: Text(_timer.berjalan ? 'Jeda' : 'Mulai'),
                  style: FilledButton.styleFrom(
                    backgroundColor: warna,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  tooltip: 'Lewati',
                  onPressed: _timer.lewati,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text('${_timer.sesiSelesai} sesi fokus selesai'),
                subtitle: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4, top: 4),
                        child: Icon(
                          Icons.water_drop,
                          size: 18,
                          color: i < _ikonTerisi(_timer.sesiSelesai)
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!fokus)
              Card(
                color: scheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.self_improvement),
                  title: const Text('Berdiri, regangkan otot, dan minum'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showBreakSheet(context, _timer),
                ),
              ),
          ],
        );
      },
    );
  }
}
