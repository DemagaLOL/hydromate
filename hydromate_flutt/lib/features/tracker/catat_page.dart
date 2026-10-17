import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import 'celebration.dart';
import 'drink_style.dart';
import 'wave_progress.dart';

// Ikon garis per jenis minuman (gaya desain)
const _ikonGaris = {
  'Air putih': Icons.water_drop_outlined,
  'Kopi': Icons.coffee_outlined,
  'Teh': Icons.emoji_food_beverage_outlined,
  'Boba': Icons.local_drink_outlined,
  'Energi': Icons.bolt_outlined,
};

IconData ikonGaris(String jenis) => _ikonGaris[jenis] ?? Icons.local_drink;

// Buka halaman catat minuman. [lokasi] diisi bila dicatat dari peta refill.
Future<void> bukaCatat(
  BuildContext context, {
  String jenis = 'Air putih',
  int ml = 250,
  String? lokasi,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CatatPage(jenisAwal: jenis, mlAwal: ml, lokasi: lokasi),
    ),
  );
}

// Halaman "Catat minuman": pilih jenis, volume, dan waktu minum
class CatatPage extends StatefulWidget {
  final String jenisAwal;
  final int mlAwal;
  final String? lokasi;

  const CatatPage({
    super.key,
    this.jenisAwal = 'Air putih',
    this.mlAwal = 250,
    this.lokasi,
  });

  @override
  State<CatatPage> createState() => _CatatPageState();
}

class _CatatPageState extends State<CatatPage> {
  static const _pilihanCepat = [100, 250, 500];

  late String _jenis = widget.jenisAwal;
  late int _ml = widget.mlAwal;
  final _mlCtrl = TextEditingController();
  TimeOfDay _waktu = TimeOfDay.now();

  @override
  void dispose() {
    _mlCtrl.dispose();
    super.dispose();
  }

  String get _keterangan {
    if (_ml <= 150) return 'Seteguk kecil tetap berarti.';
    if (_ml <= 300) return 'Satu gelas kecil, satu langkah baik.';
    if (_ml <= 500) return 'Segelas penuh, tubuhmu berterima kasih.';
    return 'Satu botol besar, hidrasi maksimal!';
  }

  Future<void> _pilihWaktu() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: _waktu,
      helpText: 'Waktu minum (hari ini)',
    );
    if (hasil == null) return;
    final now = TimeOfDay.now();
    // Tidak boleh di masa depan
    final masaDepan =
        hasil.hour * 60 + hasil.minute > now.hour * 60 + now.minute;
    setState(() => _waktu = masaDepan ? now : hasil);
  }

  void _simpan() {
    final state = context.read<AppState>();
    final sebelumnya = state.targetTercapaiHariIni;
    final now = DateTime.now();
    final log = DrinkLog(
      jenis: _jenis,
      ml: _ml,
      waktu: DateTime(now.year, now.month, now.day, _waktu.hour, _waktu.minute),
    );
    state.addLog(log);
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TercatatPage(
          log: log,
          baruTercapai: !sebelumnya && state.targetTercapaiHariIni,
          lokasi: widget.lokasi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.select<AppState, String>((s) => s.profile?.nama ?? '');
    final koef = koefisienHidrasi[_jenis] ?? 1.0;
    final efektif = _ml * koef;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            BarAtas(
              judul: 'Catat minuman',
              kanan: AvatarInisial(nama: nama),
            ),
            const SizedBox(height: 18),
            const Text(
              'Baru minum apa?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (i, jenis) in koefisienHidrasi.keys.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _PetakJenis(
                      jenis: jenis,
                      terpilih: jenis == _jenis,
                      onTap: () => setState(() => _jenis = jenis),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: _Gelas(ml: _ml, warna: warnaDari(_jenis)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatRibuan(_ml),
                  style: const TextStyle(
                    fontSize: 64,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ml',
                  style: TextStyle(fontSize: 22, color: AppColors.teksRedup),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _keterangan,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.teksRedup, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih volume',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, v) in _pilihanCepat.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _PilihanVolume(
                      ml: v,
                      terpilih: v == _ml && _mlCtrl.text.isEmpty,
                      onTap: () => setState(() {
                        _mlCtrl.clear();
                        _ml = v;
                      }),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mlCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                hintText: 'Atau masukkan jumlah sendiri',
                suffixText: 'ml',
                suffixStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n > 0) setState(() => _ml = n.clamp(1, 3000));
              },
            ),
            const SizedBox(height: 12),
            KartuPutih(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              onTap: _pilihWaktu,
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Waktu minum',
                      style: TextStyle(
                        color: AppColors.teksRedup,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    'Hari ini, ${_waktu.hour.toString().padLeft(2, '0')}.'
                    '${_waktu.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CatatanKecil(
              _jenis == 'Air putih'
                  ? 'Kopi, teh, boba, dan minuman energi dihitung sebagian '
                        'sebagai air efektif. Tetap perhatikan kandungan '
                        'kafein dan gulanya.'
                  : '${_jenis.toLowerCase()} dihitung ×$koef, jadi ≈ '
                        '${formatRibuan(efektif)} ml air efektif. Tetap '
                        'perhatikan kandungan kafein dan gulanya.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.check),
              label: Text(
                'Simpan ${formatRibuan(_ml)} ml ${_jenis.toLowerCase()}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetakJenis extends StatelessWidget {
  final String jenis;
  final bool terpilih;
  final VoidCallback onTap;

  const _PetakJenis({
    required this.jenis,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = terpilih ? Colors.white : AppColors.teksRedup;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: terpilih ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(radiusKartu),
        border: Border.all(
          color: terpilih ? AppColors.primary : AppColors.garis,
          width: 1.2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radiusKartu),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(ikonGaris(jenis), color: warna, size: 28),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    jenis,
                    style: TextStyle(
                      color: terpilih ? Colors.white : AppColors.teks,
                      fontWeight: FontWeight.w800,
                    ),
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

class _PilihanVolume extends StatelessWidget {
  final int ml;
  final bool terpilih;
  final VoidCallback onTap;

  const _PilihanVolume({
    required this.ml,
    required this.terpilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: terpilih ? AppColors.tint : Colors.white,
        borderRadius: BorderRadius.circular(radiusTombol),
        border: Border.all(
          color: terpilih ? AppColors.primary : AppColors.garis,
          width: terpilih ? 2 : 1.2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radiusTombol),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                '$ml ml',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: terpilih ? AppColors.primary : AppColors.teksRedup,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Gelas bening berisi cairan bergradien setinggi volume (penuh = 600 ml)
class _Gelas extends StatelessWidget {
  final int ml;
  final Color warna;

  const _Gelas({required this.ml, required this.warna});

  @override
  Widget build(BuildContext context) {
    final air = warna == warnaDari('Air putih');
    return TweenAnimationBuilder<double>(
      tween: Tween(end: (ml / 600).clamp(0.08, 1.0)),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, fraksi, _) => Container(
        width: 118,
        height: 164,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF6FA),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(10),
            bottom: Radius.circular(26),
          ),
          border: Border.all(color: AppColors.garis, width: 3),
        ),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: fraksi,
          widthFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: air
                  ? AppColors.gradienVertikal
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [warna.withValues(alpha: 0.6), warna],
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
                bottom: Radius.circular(20),
              ),
            ),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 16, top: 14),
            // Kilau di sisi kiri gelas
            child: Container(
              width: 5,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Halaman setelah mencatat: progres terbaru dan opsi membatalkan
class TercatatPage extends StatefulWidget {
  final DrinkLog log;
  final bool baruTercapai;
  final String? lokasi;

  const TercatatPage({
    super.key,
    required this.log,
    this.baruTercapai = false,
    this.lokasi,
  });

  @override
  State<TercatatPage> createState() => _TercatatPageState();
}

class _TercatatPageState extends State<TercatatPage> {
  @override
  void initState() {
    super.initState();
    if (widget.baruTercapai) {
      // Rayakan setelah halaman tampil
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showCelebration(context, streak: context.read<AppState>().streakHari);
      });
    }
  }

  void _batalkan() {
    context.read<AppState>().removeLog(widget.log);
    Navigator.pop(context);
    // Snackbar tampil di halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nama = state.profile?.nama ?? '';
    final log = widget.log;
    final jenis = log.jenis.toLowerCase();
    final tercapai = state.targetTercapaiHariIni;
    final fraksi = state.targetMl <= 0
        ? 0.0
        : state.airEfektifHariIni / state.targetMl;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            BarAtas(
              judul: '${log.jenis} tercatat',
              kanan: AvatarInisial(nama: nama),
            ),
            const SizedBox(height: 20),
            const Center(child: HydroLogo(ukuran: 104)),
            const SizedBox(height: 16),
            Center(
              child: PilLabel(
                '+${formatRibuan(log.ml)} ml $jenis tersimpan',
                ikon: Icons.check,
                kapital: false,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tercapai ? 'Target tercapai! 🎉' : 'Seteguk lebih dekat!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              widget.lokasi != null
                  ? 'Isi ulang di ${widget.lokasi}. Satu botol plastik '
                        'terselamatkan 🌱'
                  : '${nama.isEmpty ? 'Bagus' : 'Bagus, $nama'}. Kebiasaan '
                        'kecilmu mulai terasa konsisten.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: AppColors.teksRedup),
            ),
            const SizedBox(height: 24),
            Center(child: WaveProgress(fraksi: fraksi, ukuran: 260)),
            const SizedBox(height: 22),
            AngkaTarget(
              efektif: state.airEfektifHariIni,
              target: state.targetMl,
            ),
            const SizedBox(height: 10),
            Text(
              tercapai
                  ? 'Target hari ini sudah tercapai. Pengingat dimatikan.'
                  : 'Tinggal ${formatRibuan(state.sisaAirPutih)} ml lagi hari ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: AppColors.teksRedup),
            ),
            const SizedBox(height: 22),
            KartuTint(
              child: Row(
                children: [
                  Icon(
                    ikonGaris(log.jenis),
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.jenis} · ${formatRibuan(log.ml)} ml',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          log.jenis == 'Air putih'
                              ? 'Hari ini, ${formatJam(log.waktu)} · '
                                    'ditambahkan ke riwayat'
                              : 'Hari ini, ${formatJam(log.waktu)} · ≈ '
                                    '${formatRibuan(log.mlEfektif)} ml efektif',
                          style: const TextStyle(color: AppColors.teksRedup),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke beranda'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _batalkan,
              icon: const Icon(Icons.undo),
              label: const Text(
                'Batalkan pencatatan',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// "1.250 / 2.000 ml"
class AngkaTarget extends StatelessWidget {
  final double efektif;
  final int target;

  const AngkaTarget({super.key, required this.efektif, required this.target});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: efektif),
          duration: const Duration(milliseconds: 900),
          builder: (context, v, _) => Text(
            formatRibuan(v),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          ' / ${formatRibuan(target)} ml',
          style: const TextStyle(fontSize: 20, color: AppColors.teksRedup),
        ),
      ],
    );
  }
}
