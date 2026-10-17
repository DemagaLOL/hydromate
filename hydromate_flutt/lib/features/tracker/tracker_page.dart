import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../focus/focus_page.dart';
import '../focus/pomodoro_timer.dart';
import '../profile/settings_page.dart';
import '../reminder/reminder_planner.dart';
import '../reminder/schedule_page.dart';
import 'catat_page.dart';
import 'drink_style.dart';
import 'wave_progress.dart';
import 'weather_service.dart';

// Halaman Beranda: progres air hari ini, catat cepat, dan ritme hari ini
class TrackerPage extends StatefulWidget {
  // Dipanggil saat "Lihat semua" / kartu catatan ditekan (pindah ke Statistik)
  final VoidCallback? onLihatStatistik;

  const TrackerPage({super.key, this.onLihatStatistik});

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
    state.suhuTerakhir = suhu;
    state.perbaruiTarget();
  }

  String get _sapaan {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Pagi';
    if (jam < 15) return 'Siang';
    if (jam < 18) return 'Sore';
    return 'Malam';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nama = state.profile?.nama ?? '';
    final now = DateTime.now();
    final kelasHariIni = state.schedules.where((j) => j.hari == now.weekday);
    final fraksi = state.targetMl <= 0
        ? 0.0
        : state.airEfektifHariIni / state.targetMl;
    final suhu = _suhu;

    return RefreshIndicator(
      onRefresh: _muatCuaca,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          BarAtas(
            judul: 'HydroMate',
            kembali: false,
            logo: true,
            kanan: AvatarInisial(
              nama: nama,
              onTap: () => SettingsPage.buka(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama.isEmpty ? '$_sapaan!' : '$_sapaan, $nama!',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${tanggalPanjang(now)} · '
                      '${kelasHariIni.length >= 2 ? 'hari yang padat?' : 'jaga ritmemu'}'
                      '${suhu == null ? '' : ' · ${suhu.round()}°C'}',
                      style: const TextStyle(
                        color: AppColors.teksRedup,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PilLabel(
                '${state.streakHari} hari',
                ikon: Icons.local_fire_department_outlined,
                kapital: false,
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'AIR EFEKTIF HARI INI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.teksRedup,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: WaveProgress(fraksi: fraksi, ukuran: 290)),
          const SizedBox(height: 22),
          AngkaTarget(efektif: state.airEfektifHariIni, target: state.targetMl),
          const SizedBox(height: 8),
          Text(
            state.targetTercapaiHariIni
                ? 'Target tercapai. Hebat, pertahankan besok!'
                : 'Tinggal ${formatRibuan(state.sisaAirPutih)} ml lagi. '
                      'Pelan-pelan saja.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.teksRedup),
          ),
          if (suhu != null && suhu >= 30) ...[
            const SizedBox(height: 8),
            const Center(
              child: PilLabel(
                'Cuaca panas · target +300 ml',
                ikon: Icons.wb_sunny_outlined,
                kapital: false,
                warna: Color(0xFFD9822B),
                latar: AppColors.hangat,
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => bukaCatat(context),
            icon: const Icon(Icons.add),
            label: const Text('Catat air putih  +250 ml'),
          ),
          const SizedBox(height: 16),
          const _KartuPengingat(),
          if (state.tambahanDariMinumanLain > 0) ...[
            const SizedBox(height: 12),
            KartuTint(
              warna: AppColors.hangat,
              child: Row(
                children: [
                  const Icon(Icons.balance, color: AppColors.coklat),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Minuman lain hari ini menambah kebutuhan '
                      '±${formatRibuan(state.tambahanDariMinumanLain)} ml '
                      'air putih.',
                      style: const TextStyle(color: AppColors.coklat),
                    ),
                  ),
                ],
              ),
            ),
          ],
          JudulBagian(
            'Ritmemu hari ini',
            aksi: TautanTeks('Lihat semua', onTap: widget.onLihatStatistik),
          ),
          Row(
            children: [
              const Expanded(child: _KartuFokus()),
              const SizedBox(width: 14),
              Expanded(
                child: _KartuRitme(
                  ikon: Icons.local_drink_outlined,
                  judul: '${state.logsHariIni.length} catatan air',
                  isi: state.logsHariIni.isEmpty
                      ? 'Belum ada hari ini'
                      : 'Terakhir ${formatJam(state.logsHariIni.last.waktu)}',
                  onTap: widget.onLihatStatistik,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Kartu pengingat berikutnya, dengan keterangan bila digeser karena kelas
class _KartuPengingat extends StatelessWidget {
  const _KartuPengingat();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final menitSekarang = now.hour * 60 + now.minute;
    final profil = state.profile;

    final String judul;
    final String isi;
    final IconData ikon;
    if (profil != null && !profil.pengingatAktif) {
      ikon = Icons.notifications_off_outlined;
      judul = 'Pengingat dimatikan';
      isi = 'Aktifkan lagi di Profil & pengaturan.';
    } else if (state.targetTercapaiHariIni) {
      ikon = Icons.check_circle_outline;
      judul = 'Target hari ini tercapai';
      isi = 'Pengingat hari ini dimatikan otomatis.';
    } else {
      final berikut = rencanaPengingat(
        now.weekday,
        profil: profil,
        jadwal: state.schedules,
        logs: state.logs,
      ).where((m) => m > menitSekarang).firstOrNull;
      if (berikut == null) {
        ikon = Icons.nightlight_outlined;
        judul = 'Tidak ada pengingat lagi hari ini';
        isi = 'Jam tenang. Sampai besok!';
      } else {
        final setelah = kelasBerakhirPada(
          now.weekday,
          berikut,
          state.schedules,
        );
        final sebelum = kelasSetelah(now.weekday, berikut, state.schedules);
        ikon = setelah != null
            ? Icons.notifications_paused_outlined
            : Icons.notifications_active_outlined;
        judul = setelah != null
            ? '${formatMenit(berikut)} · setelah kelas selesai'
            : sebelum != null
            ? '${formatMenit(berikut)} · sebelum kelas'
            : '${formatMenit(berikut)} · pengingat berikutnya';
        isi = setelah != null
            ? 'Pengingat ditunda selama ${_nama(setelah)}.'
            : sebelum != null
            ? 'Minum dulu sebelum ${_nama(sebelum)} dimulai.'
            : 'Di luar jam kuliahmu.';
      }
    }

    return KartuTint(
      onTap: () => SchedulePage.buka(context),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(ikon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(isi, style: const TextStyle(color: AppColors.teksRedup)),
                const Text(
                  'Lihat jadwal ›',
                  style: TextStyle(color: AppColors.teksRedup),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _nama(ClassSchedule k) => k.nama.isEmpty ? 'kelas' : k.nama;
}

// Kartu sesi fokus: tampilkan sisa waktu bila sedang berjalan
class _KartuFokus extends StatelessWidget {
  const _KartuFokus();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroTimer>();
    final isi = timer.berjalan
        ? '${timer.fase == FasePomodoro.fokus ? 'Fokus' : 'Jeda'} · '
              '${formatSisa(timer.sisa)}'
        : 'Mulai 25 menit ›';
    return _KartuRitme(
      ikon: Icons.timer_outlined,
      judul: 'Sesi fokus',
      isi: isi,
      onTap: () => FocusPage.buka(context),
    );
  }
}

class _KartuRitme extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String isi;
  final VoidCallback? onTap;

  const _KartuRitme({
    required this.ikon,
    required this.judul,
    required this.isi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KartuPutih(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(isi, style: const TextStyle(color: AppColors.teksRedup)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
