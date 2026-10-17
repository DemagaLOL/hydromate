import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import 'break_sheet.dart';
import 'pomodoro_timer.dart';

// Halaman "Fokus & tetap terhidrasi": Pomodoro dengan jeda minum.
// Timer hidup di level aplikasi (Provider) sehingga tetap berjalan saat
// halaman ditutup; notifikasi akhir fase diatur oleh ReminderService.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  static Future<void> buka(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FocusPage()),
  );

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  late final PomodoroTimer _timer;

  @override
  void initState() {
    super.initState();
    _timer = context.read<PomodoroTimer>();
    _timer.onFaseBerubah = _saatFaseBerubah;
  }

  @override
  void dispose() {
    // Saat halaman ditutup, pergantian fase cukup lewat notifikasi
    if (_timer.onFaseBerubah == _saatFaseBerubah) _timer.onFaseBerubah = null;
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
        ..showSnackBar(
          const SnackBar(
            content: Text('Jeda selesai. Tekan Mulai untuk sesi berikutnya.'),
          ),
        );
    }
  }

  Future<void> _ubahTugas() async {
    final ctrl = TextEditingController(text: _timer.tugas);
    final hasil = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sedang mengerjakan apa?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (hasil != null && hasil.isNotEmpty) _timer.aturTugas(hasil);
  }

  void _gantiMode(bool demo) {
    if (demo) {
      _timer.aturDurasi(
        const Duration(seconds: 25),
        const Duration(seconds: 5),
      );
    } else {
      _timer.aturDurasi(
        const Duration(minutes: 25),
        const Duration(minutes: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroTimer>();
    final nama = context.select<AppState, String>((s) => s.profile?.nama ?? '');
    final fokus = timer.fase == FasePomodoro.fokus;
    final demo = timer.durasiFokus.inSeconds < 60;
    final satuan = demo ? 'dtk' : 'mnt';
    final menitFokus = demo
        ? timer.durasiFokus.inSeconds
        : timer.durasiFokus.inMinutes;
    final menitJeda = demo
        ? timer.durasiIstirahat.inSeconds
        : timer.durasiIstirahat.inMinutes;
    final sesiKe = timer.sesiSelesai % 4 + (fokus ? 1 : 0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            BarAtas(
              judul: 'Fokus & tetap terhidrasi',
              kanan: AvatarInisial(nama: nama),
            ),
            const SizedBox(height: 18),
            SegmenPil<FasePomodoro>(
              pilihan: [
                (FasePomodoro.fokus, 'Fokus · $menitFokus $satuan'),
                (FasePomodoro.istirahat, 'Jeda · $menitJeda $satuan'),
              ],
              terpilih: timer.fase,
              // Saat timer berhenti, ketuk fase lain untuk melompat ke sana
              onPilih: (f) {
                if (f != timer.fase && !timer.berjalan) timer.lewati();
              },
            ),
            const SizedBox(height: 22),
            Center(
              child: PilLabel(
                'Sesi ${sesiKe.clamp(1, 4)} dari 4',
                ikon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fokus ? 'Satu tugas dulu.' : 'Waktunya jeda hidrasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _ubahTugas,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          timer.tugas,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.teksRedup,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.teksRedup,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _CincinTimer(
                progres: timer.progres,
                teks: formatSisa(timer.sisa),
                keterangan: demo ? 'detik tersisa' : 'menit tersisa',
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: timer.berjalan ? timer.jeda : timer.mulai,
                    icon: Icon(
                      timer.berjalan ? Icons.pause : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      timer.berjalan
                          ? 'Jeda'
                          : timer.progres > 0
                          ? 'Lanjut'
                          : 'Mulai',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tint,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: timer.ulang,
                    icon: const Icon(Icons.stop_outlined),
                    label: const Text('Selesai'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            KartuTint(
              onTap: fokus ? null : () => showBreakSheet(context, timer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fokus
                              ? 'Berikutnya: jeda hidrasi'
                              : 'Sekarang: jeda hidrasi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        '$menitJeda ${demo ? 'detik' : 'menit'}',
                        style: const TextStyle(
                          color: AppColors.aksen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.local_drink_outlined,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Minum 250 ml & regangkan badan',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              fokus
                                  ? 'Berdiri sebentar, rilekskan bahu. Catat '
                                        'airnya setelah kamu minum.'
                                  : 'Ketuk untuk membuka panduan jeda dan '
                                        'mencatat minum.',
                              style: const TextStyle(
                                color: AppColors.teksRedup,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const CatatanKecil(
              'Pengingat minum senyap selama sesi fokus.',
              ikon: Icons.notifications_off_outlined,
              tengah: true,
            ),
            const SizedBox(height: 8),
            // Mode demo untuk presentasi (25/5 detik)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mode demo (detik)',
                  style: TextStyle(color: AppColors.teksRedup),
                ),
                Switch(
                  value: demo,
                  onChanged: timer.berjalan ? null : _gantiMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Cincin progres timer: lintasan lembut, busur gradien, dan titik di ujung
class _CincinTimer extends StatelessWidget {
  final double progres;
  final String teks;
  final String keterangan;

  const _CincinTimer({
    required this.progres,
    required this.teks,
    required this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 290,
      child: CustomPaint(
        painter: _CincinPainter(progres),
        child: Center(
          child: Container(
            width: 228,
            height: 228,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  teks,
                  style: const TextStyle(
                    fontSize: 64,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  keterangan,
                  style: const TextStyle(
                    color: AppColors.teksRedup,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CincinPainter extends CustomPainter {
  final double progres;

  _CincinPainter(this.progres);

  @override
  void paint(Canvas canvas, Size size) {
    final pusat = size.center(Offset.zero);
    final r = size.width / 2 - 10;
    canvas.drawCircle(
      pusat,
      size.width / 2,
      Paint()..color = const Color(0xFFEAF5FA),
    );
    canvas.drawCircle(
      pusat,
      r,
      Paint()
        ..color = const Color(0xFFDDEDF5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    if (progres <= 0) return;
    final sudut = 2 * math.pi * progres;
    final rect = Rect.fromCircle(center: pusat, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sudut,
      false,
      Paint()
        // Gradien dimulai dari posisi jam 12, mengikuti arah busur
        ..shader = const SweepGradient(
          colors: [AppColors.secondary, AppColors.primary],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    // Titik di ujung busur
    final ujung = Offset(
      pusat.dx + r * math.cos(-math.pi / 2 + sudut),
      pusat.dy + r * math.sin(-math.pi / 2 + sudut),
    );
    canvas.drawCircle(ujung, 9, Paint()..color = Colors.white);
    canvas.drawCircle(ujung, 6, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_CincinPainter old) => old.progres != progres;
}
