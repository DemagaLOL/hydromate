import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../profile/settings_page.dart';
import 'catat_page.dart';
import 'drink_style.dart';
import 'history_chart.dart';

const _hariSingkat = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

// Tab Statistik: grafik harian/mingguan, ringkasan hari ini, riwayat terbaru
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _mingguan = true;
  int _mundur = 0; // jumlah minggu/hari ke belakang

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hariIni = state.logsHariIni;
    final air = hariIni.where((l) => l.jenis == 'Air putih');
    final lain = hariIni.where((l) => l.jenis != 'Air putih');
    final mlAir = air.fold(0, (t, l) => t + l.ml);
    final mlLain = lain.fold(0, (t, l) => t + l.ml);
    // Rincian minuman lain: "Kopi 200 · teh 150"
    final perJenis = <String, int>{};
    for (final l in lain) {
      perJenis[l.jenis] = (perJenis[l.jenis] ?? 0) + l.ml;
    }
    final rincian = perJenis.entries
        .map((e) => '${e.key} ${formatRibuan(e.value)}')
        .join(' · ');
    final terbaru = state.logs.toList()
      ..sort((a, b) => b.waktu.compareTo(a.waktu));
    final botol = botolTerhemat(state.logs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        BarAtas(
          judul: 'Statistik minummu',
          kembali: false,
          logo: true,
          kanan: AvatarInisial(
            nama: state.profile?.nama ?? '',
            onTap: () => SettingsPage.buka(context),
          ),
        ),
        const SizedBox(height: 16),
        SegmenPil<bool>(
          pilihan: const [(false, 'Harian'), (true, 'Mingguan')],
          terpilih: _mingguan,
          onPilih: (v) => setState(() {
            _mingguan = v;
            _mundur = 0;
          }),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey('$_mingguan$_mundur'),
            child: _mingguan
                ? _KartuMingguan(
                    logs: state.logs,
                    target: state.targetMl,
                    mundur: _mundur,
                    onGeser: (d) => setState(() => _mundur += d),
                  )
                : _KartuHarian(
                    logs: state.logs,
                    mundur: _mundur,
                    onGeser: (d) => setState(() => _mundur += d),
                  ),
          ),
        ),
        JudulBagian(
          'Hari ini',
          aksi: Text(
            '${state.persenHariIni.clamp(0, 999)}% dari target',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KartuRingkas(
                ikon: Icons.water_drop_outlined,
                judul: 'Air putih',
                nilai: '${formatRibuan(mlAir)} ml',
                isi: '${air.length} kali minum',
                warna: AppColors.aksen,
                latar: AppColors.tint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _KartuRingkas(
                ikon: Icons.coffee_outlined,
                judul: 'Minuman lain',
                nilai: '${formatRibuan(mlLain)} ml',
                isi: rincian.isEmpty ? 'Belum ada' : rincian,
                warna: AppColors.coklat,
                latar: AppColors.hangat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Minuman lain dihitung sebagian sebagai air efektif (teh ×0,9, kopi '
          '×0,8, boba ×0,7, energi ×0,6). Perhatikan juga kandungan kafein '
          'dan gula.',
          style: TextStyle(color: AppColors.teksRedup),
        ),
        if (botol > 0) ...[
          const SizedBox(height: 14),
          KartuTint(
            warna: const Color(0xFFE5F6EC),
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.sukses),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '≈ $botol botol plastik 600 ml terhemat sejak kamu mulai '
                    'mencatat air putih.',
                    style: const TextStyle(
                      color: Color(0xFF1F7A4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        JudulBagian(
          'Riwayat terbaru',
          aksi: TautanTeks(
            'Semua catatan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatPage()),
            ),
          ),
        ),
        KartuPutih(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: terbaru.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada catatan. Mulai dari segelas air putih!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.teksRedup),
                  ),
                )
              : Column(
                  children: [
                    for (final l in terbaru.take(5)) _BarisRiwayat(log: l),
                  ],
                ),
        ),
      ],
    );
  }
}

class _KartuMingguan extends StatelessWidget {
  final List<DrinkLog> logs;
  final int target;
  final int mundur;
  final ValueChanged<int> onGeser;

  const _KartuMingguan({
    required this.logs,
    required this.target,
    required this.mundur,
    required this.onGeser,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final akhir = DateTime(now.year, now.month, now.day - 7 * mundur);
    final awal = DateTime(akhir.year, akhir.month, akhir.day - 6);
    final total = totalEfektifPerHari(logs, 7, sekarang: akhir);
    final label = [
      for (var i = 0; i < 7; i++)
        _hariSingkat[DateTime(awal.year, awal.month, awal.day + i).weekday],
    ];
    final tercapai = total.where((t) => t >= target).length;
    final rentang = awal.month == akhir.month
        ? '${awal.day}–${akhir.day} ${namaBulan(akhir.month)}'
        : '${awal.day} ${namaBulan(awal.month)} – '
              '${akhir.day} ${namaBulan(akhir.month)}';

    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KepalaGrafik(
            judul: rentang,
            sub: 'Air efektif (ml) · target ${formatRibuan(target)} ml / hari',
            onMundur: () => onGeser(1),
            onMaju: mundur > 0 ? () => onGeser(-1) : null,
          ),
          const SizedBox(height: 16),
          GrafikBatang(
            nilai: total,
            label: label,
            maks: target.toDouble(),
            sorot: mundur == 0 ? 6 : null,
          ),
          const SizedBox(height: 16),
          Text(
            '$tercapai dari 7 hari mencapai target. '
            '${tercapai >= 5 ? 'Luar biasa, pertahankan!' : 'Terus jaga ritmemu.'}',
            style: const TextStyle(color: AppColors.teksRedup),
          ),
        ],
      ),
    );
  }
}

class _KartuHarian extends StatelessWidget {
  final List<DrinkLog> logs;
  final int mundur;
  final ValueChanged<int> onGeser;

  const _KartuHarian({
    required this.logs,
    required this.mundur,
    required this.onGeser,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tgl = DateTime(now.year, now.month, now.day - mundur);
    // Blok 2 jam dari 06.00 sampai 22.00
    final nilai = List<double>.filled(8, 0);
    for (final l in logs) {
      if (tanggalSaja(l.waktu) != tgl) continue;
      final blok = ((l.waktu.hour - 6) ~/ 2).clamp(0, 7);
      nilai[blok] += l.mlEfektif;
    }
    final label = [for (var i = 0; i < 8; i++) '${6 + i * 2}'.padLeft(2, '0')];
    final maks = nilai.fold(500.0, (a, b) => a > b ? a : b);
    final puncak = nilai.indexOf(nilai.reduce((a, b) => a > b ? a : b));
    final blokSekarang = mundur == 0 ? ((now.hour - 6) ~/ 2) : null;

    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KepalaGrafik(
            judul: mundur == 0 ? 'Hari ini' : tanggalPanjang(tgl),
            sub: 'Air efektif (ml) per 2 jam',
            onMundur: () => onGeser(1),
            onMaju: mundur > 0 ? () => onGeser(-1) : null,
          ),
          const SizedBox(height: 16),
          GrafikBatang(
            nilai: nilai,
            label: label,
            maks: maks,
            sorot: blokSekarang != null && blokSekarang >= 0 && blokSekarang < 8
                ? blokSekarang
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            nilai.every((v) => v == 0)
                ? 'Belum ada catatan di hari ini.'
                : 'Paling banyak minum pukul ${label[puncak]}.00–'
                      '${(6 + puncak * 2 + 2).toString().padLeft(2, '0')}.00.',
            style: const TextStyle(color: AppColors.teksRedup),
          ),
        ],
      ),
    );
  }
}

class _KepalaGrafik extends StatelessWidget {
  final String judul;
  final String sub;
  final VoidCallback onMundur;
  final VoidCallback? onMaju;

  const _KepalaGrafik({
    required this.judul,
    required this.sub,
    required this.onMundur,
    required this.onMaju,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(sub, style: const TextStyle(color: AppColors.teksRedup)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sebelumnya',
          onPressed: onMundur,
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
        IconButton(
          tooltip: 'Berikutnya',
          onPressed: onMaju,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _KartuRingkas extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String nilai;
  final String isi;
  final Color warna;
  final Color latar;

  const _KartuRingkas({
    required this.ikon,
    required this.judul,
    required this.nilai,
    required this.isi,
    required this.warna,
    required this.latar,
  });

  @override
  Widget build(BuildContext context) {
    return KartuTint(
      warna: latar,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: warna, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  judul,
                  style: TextStyle(color: warna, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.teksRedup),
          ),
        ],
      ),
    );
  }
}

// Satu baris riwayat: ikon, jenis, jam, volume
class _BarisRiwayat extends StatelessWidget {
  final DrinkLog log;
  final bool tampilTanggal;

  const _BarisRiwayat({required this.log, this.tampilTanggal = false});

  @override
  Widget build(BuildContext context) {
    final air = log.jenis == 'Air putih';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            ikonGaris(log.jenis),
            color: air ? AppColors.aksen : AppColors.coklat,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              log.jenis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          Text(
            tampilTanggal ||
                    tanggalSaja(log.waktu) == tanggalSaja(DateTime.now())
                ? formatJam(log.waktu)
                : '${log.waktu.day}/${log.waktu.month} ${formatJam(log.waktu)}',
            style: const TextStyle(color: AppColors.teksRedup, fontSize: 16),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(
              '${formatRibuan(log.ml)} ml',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Semua catatan dikelompokkan per tanggal; geser untuk menghapus
class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final semua = state.logs.toList()
      ..sort((a, b) => b.waktu.compareTo(a.waktu));
    final perTanggal = <DateTime, List<DrinkLog>>{};
    for (final l in semua) {
      perTanggal.putIfAbsent(tanggalSaja(l.waktu), () => []).add(l);
    }
    final total = totalEfektifPerTanggal(state.logs);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            BarAtas(
              judul: 'Semua catatan',
              kanan: TombolKotak(
                ikon: Icons.add,
                tooltip: 'Catat minuman',
                warnaIkon: AppColors.primary,
                onTap: () => bukaCatat(context),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Geser catatan ke samping untuk menghapus.',
              style: TextStyle(color: AppColors.teksRedup),
            ),
            if (semua.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada catatan.', textAlign: TextAlign.center),
              ),
            for (final e in perTanggal.entries) ...[
              JudulBagian(
                tanggalPanjang(e.key),
                aksi: Text(
                  '${formatRibuan(total[e.key] ?? 0)} ml efektif',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: (total[e.key] ?? 0) >= state.targetMl
                        ? AppColors.sukses
                        : AppColors.teksRedup,
                  ),
                ),
              ),
              KartuPutih(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (final l in e.value)
                      Dismissible(
                        key: ObjectKey(l),
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: const Color(0xFFFDECEC),
                          padding: const EdgeInsets.only(right: 12),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        onDismissed: (_) {
                          state.removeLog(l);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${l.jenis} ${formatRibuan(l.ml)} ml dihapus',
                                ),
                                action: SnackBarAction(
                                  label: 'Batalkan',
                                  onPressed: () => state.addLog(l),
                                ),
                              ),
                            );
                        },
                        child: _BarisRiwayat(log: l, tampilTanggal: true),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
