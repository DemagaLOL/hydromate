import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../tracker/drink_volume_sheet.dart';
import 'pomodoro_timer.dart';

// Gerakan peregangan singkat, dipilih acak tiap istirahat
const _gerakanPeregangan = [
  'Putar bahu ke belakang 10 kali',
  'Miringkan leher ke kiri dan kanan, tahan 15 detik',
  'Angkat kedua tangan ke atas kepala, tahan 15 detik',
  'Putar pergelangan tangan dan kaki 10 kali',
  'Jalan kaki santai selama 1 menit',
  'Sentuh ujung kaki perlahan, tahan 10 detik',
];

Future<void> showBreakSheet(BuildContext context, PomodoroTimer timer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BreakSheet(timer: timer),
  );
}

// Panduan istirahat: berdiri, regangkan otot, minum air
class BreakSheet extends StatefulWidget {
  final PomodoroTimer timer;

  const BreakSheet({super.key, required this.timer});

  @override
  State<BreakSheet> createState() => _BreakSheetState();
}

class _BreakSheetState extends State<BreakSheet> {
  final _gerakan =
      _gerakanPeregangan[math.Random().nextInt(_gerakanPeregangan.length)];
  bool _berdiri = false;
  bool _regangkan = false;
  bool _minum = false;

  Future<void> _catatMinum() async {
    final ml = await showDrinkVolumeSheet(context, 'Air putih');
    if (ml == null || !mounted) return;
    context
        .read<AppState>()
        .addLog(DrinkLog(jenis: 'Air putih', ml: ml, waktu: DateTime.now()));
    setState(() => _minum = true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semuaSelesai = _berdiri && _regangkan && _minum;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Waktunya istirahat!',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            // Sisa waktu istirahat ikut berjalan di dalam sheet
            ListenableBuilder(
              listenable: widget.timer,
              builder: (context, _) => Text(
                widget.timer.fase == FasePomodoro.istirahat
                    ? 'Sisa istirahat ${formatSisa(widget.timer.sisa)}'
                    : 'Istirahat selesai, siap fokus lagi!',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _berdiri,
              onChanged: (v) => setState(() => _berdiri = v ?? false),
              secondary: const Icon(Icons.accessibility_new),
              title: const Text('Berdiri dari kursi'),
              subtitle: const Text('Beri jeda untuk punggung dan mata'),
            ),
            CheckboxListTile(
              value: _regangkan,
              onChanged: (v) => setState(() => _regangkan = v ?? false),
              secondary: const Icon(Icons.self_improvement),
              title: const Text('Regangkan otot'),
              subtitle: Text(_gerakan),
            ),
            CheckboxListTile(
              value: _minum,
              onChanged: (v) => setState(() => _minum = v ?? false),
              secondary: const Icon(Icons.water_drop),
              title: const Text('Minum air'),
              subtitle: const Text('Satu gelas air putih'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _minum ? null : _catatMinum,
              icon: const Icon(Icons.local_drink),
              label: Text(_minum ? 'Minum sudah dicatat' : 'Catat minum'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(semuaSelesai ? 'Mantap, selesai!' : 'Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}
