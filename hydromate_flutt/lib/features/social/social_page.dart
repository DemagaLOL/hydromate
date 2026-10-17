import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../profile/settings_page.dart';
import 'badges.dart';
import 'social_service.dart';

// Tab Teman: tantangan 7 hari, streak, peringkat hari ini, dan lencana
class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  late final AppState _state;
  late bool _modeGrup;
  Timer? _debounce;

  // Aliran leaderboard disimpan agar tidak dibuat ulang setiap build
  Stream<List<EntriPeringkat>>? _aliran;
  String? _kunciAliran;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    _modeGrup = _state.kodeGrup != null;
    // Statistik dikirim ke Supabase setiap kali catatan/profil berubah
    _state.addListener(_sinkronNanti);
    _sinkronNanti();
  }

  @override
  void dispose() {
    _state.removeListener(_sinkronNanti);
    _debounce?.cancel();
    super.dispose();
  }

  void _sinkronNanti() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(seconds: 2),
      () => SocialService.sinkron(_state),
    );
  }

  Stream<List<EntriPeringkat>> _aliranUntuk(String? kode) {
    final kunci = '${_modeGrup ? 'grup' : 'kampus'}:$kode';
    if (_aliran == null || _kunciAliran != kunci) {
      _kunciAliran = kunci;
      _aliran = SocialService.pantau(kodeGrup: _modeGrup ? kode : null)
          .asBroadcastStream();
    }
    return _aliran!;
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _undang() async {
    var kode = _state.kodeGrup;
    if (kode == null) {
      kode = buatKodeGrup();
      _state.setKodeGrup(kode);
      setState(() => _modeGrup = true);
    }
    await Clipboard.setData(ClipboardData(text: kode));
    _pesan('Kode grup $kode disalin. Bagikan ke temanmu!');
  }

  Future<void> _gabung() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final kode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabung tantangan'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Kode grup 6 karakter'),
            validator: (v) => kodeGrupValid((v ?? '').trim().toUpperCase())
                ? null
                : 'Kode tidak valid',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, ctrl.text.trim().toUpperCase());
              }
            },
            child: const Text('Gabung'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (kode == null) return;
    if (!await SocialService.grupAda(kode)) {
      _pesan('Grup $kode tidak ditemukan');
      return;
    }
    _state.setKodeGrup(kode);
    setState(() => _modeGrup = true);
    _pesan('Berhasil bergabung ke grup $kode');
  }

  Future<void> _keluar() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari grup?'),
        content: const Text('Kamu bisa bergabung lagi dengan kode yang sama.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ya != true) return;
    _state.setKodeGrup(null);
    setState(() => _modeGrup = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final kode = state.kodeGrup;
    final punyaNama = (state.profile?.nama.trim().length ?? 0) >= 2;
    final online = SocialService.online && punyaNama;
    final lencana = hitungLencana(
      logs: state.logs,
      target: state.targetMl,
      streak: state.streakHari,
    );

    Widget isi(List<EntriPeringkat> data, {required bool contoh}) =>
        _IsiTantangan(
          data: data,
          contoh: contoh,
          streakSaya: state.streakHari,
          grup: _modeGrup && kode != null,
        );

    final Widget konten;
    if (!online) {
      konten = isi(dataContoh(state, grup: _modeGrup), contoh: true);
    } else {
      konten = StreamBuilder<List<EntriPeringkat>>(
        stream: _aliranUntuk(kode),
        builder: (context, snap) {
          if (snap.hasError) {
            return isi(dataContoh(state, grup: _modeGrup), contoh: true);
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return isi(snap.data!, contoh: false);
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        BarAtas(
          judul: 'Lebih seru bareng',
          kembali: false,
          logo: true,
          kanan: AvatarInisial(
            nama: state.profile?.nama ?? '',
            onTap: () => SettingsPage.buka(context),
          ),
        ),
        const SizedBox(height: 16),
        SegmenPil<bool>(
          pilihan: [
            (true, kode == null ? 'Grup' : 'Grup $kode'),
            (false, 'Kampus'),
          ],
          terpilih: _modeGrup,
          onPilih: (v) => setState(() => _modeGrup = v),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey('$_modeGrup$kode$online'),
            child: konten,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: kode == null ? _gabung : _undang,
                child: Text(kode == null ? 'Gabung tantangan' : 'Undang teman'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tint,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: kode == null ? _undang : _keluar,
                child: Text(kode == null ? 'Buat grup' : 'Keluar grup'),
              ),
            ),
          ],
        ),
        const JudulBagian('Lencana'),
        _GridLencana(lencana: lencana),
      ],
    );
  }
}

// Kartu tantangan, streak, dan peringkat
class _IsiTantangan extends StatelessWidget {
  final List<EntriPeringkat> data;
  final bool contoh;
  final int streakSaya;
  final bool grup;

  const _IsiTantangan({
    required this.data,
    required this.contoh,
    required this.streakSaya,
    required this.grup,
  });

  @override
  Widget build(BuildContext context) {
    // Streak grup = streak terendah anggota (semua harus konsisten)
    final streakGrup = grup && data.isNotEmpty
        ? data.map((e) => e.streak).reduce((a, b) => a < b ? a : b)
        : streakSaya;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KartuTantangan(peserta: data.length, contoh: contoh),
        const SizedBox(height: 16),
        KartuPutih(
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.primary,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grup
                          ? 'Streak grup: $streakGrup hari'
                          : 'Streak-mu: $streakGrup hari',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Saling menyemangati, bukan saling memaksa.',
                      style: TextStyle(color: AppColors.teksRedup),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        JudulBagian(
          'Peringkat hari ini',
          aksi: Text(
            contoh
                ? (grup ? 'Grup contoh' : 'Data contoh')
                : '${data.length} orang',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (data.isEmpty)
          const KartuPutih(
            child: Text(
              'Belum ada anggota. Undang teman dengan kode grupmu!',
              textAlign: TextAlign.center,
            ),
          ),
        for (final (i, e) in data.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BarisPeringkat(peringkat: i + 1, e: e),
          ),
        const Text(
          'Peringkat dari persentase target pribadi, maksimal 100%. Minum '
          'berlebih tidak menambah poin.',
          style: TextStyle(color: AppColors.teksRedup),
        ),
      ],
    );
  }
}

// Kartu gradien "Tantangan kampus · 7 hari" dengan kotak hari Senin–Minggu
class _KartuTantangan extends StatelessWidget {
  final int peserta;
  final bool contoh;

  const _KartuTantangan({required this.peserta, required this.contoh});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final hariIni = tanggalSaja(now);
    final senin = hariIni.subtract(Duration(days: now.weekday - 1));
    final minggu = senin.add(const Duration(days: 6));
    final total = totalEfektifPerTanggal(state.logs);
    final rentang = senin.month == minggu.month
        ? '${senin.day}–${minggu.day} ${namaBulan(minggu.month)}'
        : '${senin.day} ${namaBulan(senin.month)} – ${minggu.day} '
              '${namaBulan(minggu.month)}';

    return KartuGradien(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'TANTANGAN KAMPUS · 7 HARI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(Icons.emoji_events_outlined, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Seteguk bareng,\nkonsisten bareng.',
            style: TextStyle(
              fontSize: 30,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$rentang · hari ke-${now.weekday} · $peserta peserta'
            '${contoh ? ' contoh' : ''}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final d = senin.add(Duration(days: i));
                      final lalu = d.isBefore(hariIni);
                      final ini = d == hariIni;
                      final tercapai = (total[d] ?? 0) >= state.targetMl;
                      return AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: lalu || ini
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: lalu
                              ? Icon(
                                  tercapai ? Icons.check : Icons.close,
                                  color: tercapai
                                      ? AppColors.primary
                                      : AppColors.teksRedup,
                                  size: 20,
                                )
                              : FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      '${d.day}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: ini
                                            ? AppColors.primary
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BarisPeringkat extends StatelessWidget {
  final int peringkat;
  final EntriPeringkat e;

  const _BarisPeringkat({required this.peringkat, required this.e});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: e.saya ? AppColors.tint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusKartu),
        side: BorderSide(
          color: e.saya ? AppColors.aksen : AppColors.garis,
          width: e.saya ? 1.5 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$peringkat',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teksRedup,
                  fontSize: 16,
                ),
              ),
            ),
            AvatarInisial(nama: e.nama, ukuran: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.saya ? '${e.nama} (kamu)' : e.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: e.poin / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        color: AppColors.primary,
                        backgroundColor: AppColors.garis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 66,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${e.poin}%',
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridLencana extends StatelessWidget {
  final List<Lencana> lencana;

  const _GridLencana({required this.lencana});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        for (final l in lencana)
          Tooltip(
            message: l.syarat,
            triggerMode: TooltipTriggerMode.tap,
            child: KartuPutih(
              padding: const EdgeInsets.all(8),
              child: Opacity(
                opacity: l.terbuka ? 1 : 0.45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: l.warna.withValues(alpha: 0.15),
                          child: Icon(
                            l.ikon,
                            color: l.terbuka ? l.warna : Colors.grey,
                          ),
                        ),
                        if (!l.terbuka)
                          const Icon(Icons.lock, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.judul,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
