import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import 'integrasi.dart';
import 'profile_form.dart';

// Alur onboarding: sambutan -> kenali kebutuhan (1 dari 2) -> izin (2 dari 2)
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _langkah = 0;
  HasilProfil? _hasil;
  String _nama = '';

  void _selesai() {
    final h = _hasil;
    if (h == null) return;
    final state = context.read<AppState>();
    // Target manual diset dulu, lalu profil (profil memicu pindah ke beranda)
    state.targetKustom = h.targetKustom;
    state.perbaruiProfil(h.profil);
  }

  @override
  Widget build(BuildContext context) {
    final layar = switch (_langkah) {
      0 => _Sambutan(onMulai: () => setState(() => _langkah = 1)),
      1 => _LangkahKebutuhan(
        nama: _nama,
        hasilAwal: _hasil,
        onNama: (n) => setState(() => _nama = n),
        onLanjut: (h) => setState(() {
          _hasil = h;
          _langkah = 2;
        }),
      ),
      _ => _LangkahIzin(onSelesai: _selesai),
    };

    return PopScope(
      // Tombol kembali HP mundur satu langkah, bukan keluar aplikasi
      canPop: _langkah == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _langkah--);
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_langkah), child: layar),
          ),
        ),
      ),
    );
  }
}

class _Sambutan extends StatelessWidget {
  final VoidCallback onMulai;

  const _Sambutan({required this.onMulai});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Hydro'),
              TextSpan(
                text: 'Mate',
                style: TextStyle(color: AppColors.aksen),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Teman Cerdas Pengingat\nMinum Air Putih',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.teksRedup),
        ),
        const SizedBox(height: 24),
        const _IlustrasiLogo(),
        const SizedBox(height: 24),
        const Center(
          child: PilLabel('Sesuai ritmemu', ikon: Icons.auto_awesome),
        ),
        const SizedBox(height: 18),
        const Text(
          'Kuliah jalan.\nMinum tetap ingat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Pengingat yang menyesuaikan jadwalmu, bukan mengganggu waktu '
          'fokusmu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.teksRedup),
        ),
        const SizedBox(height: 18),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            PilLabel('Target personal', ikon: Icons.tune, kapital: false),
            PilLabel('Jeda yang pas', ikon: Icons.schedule, kapital: false),
          ],
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: onMulai,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Mulai kebiasaan baik'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(color: AppColors.teksRedup, fontSize: 16),
            ),
            TautanTeks(
              'Masuk',
              onTap: () => segeraHadir(context, 'Masuk dengan akun'),
            ),
          ],
        ),
      ],
    );
  }
}

// Logo besar dengan lingkaran latar, orbit, dan ikon kecil yang mengapung
class _IlustrasiLogo extends StatefulWidget {
  const _IlustrasiLogo();

  @override
  State<_IlustrasiLogo> createState() => _IlustrasiLogoState();
}

class _IlustrasiLogoState extends State<_IlustrasiLogo>
    with SingleTickerProviderStateMixin {
  late final _apung = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _apung.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return AnimatedBuilder(
            animation: _apung,
            builder: (context, _) {
              final dy = (Curves.easeInOut.transform(_apung.value) - 0.5) * 10;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Orbit elips
                  for (final (lebar, tinggi) in [(w, 150.0), (w * 0.82, 190.0)])
                    Positioned(
                      top: 150 - tinggi / 2 + 40,
                      child: Container(
                        width: lebar,
                        height: tinggi,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(lebar / 2, tinggi / 2),
                          ),
                          border: Border.all(
                            color: AppColors.garis,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 280,
                    height: 280,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F3F8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, dy),
                    child: const HydroLogo(ukuran: 200),
                  ),
                  Positioned(
                    left: 0,
                    top: 50 - dy,
                    child: const _IkonMengapung(Icons.event_available),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 70 + dy,
                    child: const _IkonMengapung(Icons.water_drop_outlined),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _IkonMengapung extends StatelessWidget {
  final IconData ikon;

  const _IkonMengapung(this.ikon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Icon(ikon, color: AppColors.primary, size: 30),
    );
  }
}

// Kepala langkah: tombol kembali, judul, "1 dari 2", dan bilah progres
class _KepalaLangkah extends StatelessWidget {
  final String judul;
  final int langkah;

  const _KepalaLangkah({required this.judul, required this.langkah});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BarAtas(
          judul: judul,
          kanan: Text(
            '$langkah dari 2',
            style: const TextStyle(
              color: AppColors.teksRedup,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 1; i <= 2; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= langkah ? AppColors.primary : AppColors.garis,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}

const _gayaJudul = TextStyle(
  fontSize: 34,
  height: 1.2,
  fontWeight: FontWeight.w900,
);
const _gayaSub = TextStyle(fontSize: 17, color: AppColors.teksRedup);

class _LangkahKebutuhan extends StatelessWidget {
  final String nama;
  final HasilProfil? hasilAwal;
  final ValueChanged<String> onNama;
  final ValueChanged<HasilProfil> onLanjut;

  const _LangkahKebutuhan({
    required this.nama,
    required this.hasilAwal,
    required this.onNama,
    required this.onLanjut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const _KepalaLangkah(judul: 'Kenali kebutuhanmu', langkah: 1),
        const Text('Target yang pas,\nbukan asal banyak.', style: _gayaJudul),
        const SizedBox(height: 8),
        Text(
          '${nama.length >= 2 ? 'Hai, $nama. ' : ''}Mulai dari rutinitasmu '
          'dulu. Kamu selalu bisa mengubahnya nanti.',
          style: _gayaSub,
        ),
        const SizedBox(height: 22),
        ProfileForm(
          awal: hasilAwal?.profil,
          targetKustomAwal: hasilAwal?.targetKustom,
          labelSimpan: 'Lanjutkan',
          onNamaBerubah: onNama,
          onSimpan: onLanjut,
        ),
      ],
    );
  }
}

class _LangkahIzin extends StatelessWidget {
  final VoidCallback onSelesai;

  const _LangkahIzin({required this.onSelesai});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const _KepalaLangkah(judul: 'Izin & integrasi', langkah: 2),
        const Text('Lebih pintar,\nkalau kamu izinkan.', style: _gayaJudul),
        const SizedBox(height: 8),
        const Text(
          'Semua opsional. HydroMate tetap bisa dipakai tanpa menghubungkan '
          'layanan apa pun.',
          style: _gayaSub,
        ),
        const SizedBox(height: 22),
        const DaftarIntegrasi(),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onSelesai,
          child: const Text('Masuk ke beranda'),
        ),
      ],
    );
  }
}
