import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../reminder/reminder_planner.dart';
import '../reminder/reminder_service.dart';
import '../tracker/drink_style.dart';
import 'demo_data.dart';
import 'integrasi.dart';
import 'profile_form.dart';

// Halaman "Profil & pengaturan"
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Future<void> buka(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsPage()),
  );

  void _buka(BuildContext context, Widget halaman) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => halaman));

  Future<void> _ubahTarget(BuildContext context, AppState state) async {
    final ctrl = TextEditingController(text: state.targetMl.toString());
    final hasil = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Target air harian'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'ml / hari'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1),
            child: const Text('Pakai otomatis'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v >= 500 && v <= 6000) Navigator.pop(context, v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (hasil == null) return;
    state.setTargetKustom(hasil == -1 ? null : hasil);
  }

  Future<void> _aturPengingat(
    BuildContext context,
    AppState state,
    UserProfile p,
    bool aktif,
  ) async {
    if (aktif) await ReminderService.mintaIzin();
    state.setProfile(p.copyWith(pengingatAktif: aktif));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    if (p == null) return const Scaffold();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            BarAtas(
              judul: 'Profil & pengaturan',
              kanan: AvatarInisial(nama: p.nama),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                AvatarInisial(nama: p.nama, ukuran: 92, kotak: true),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nama.isEmpty ? 'Tanpa nama' : p.nama,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Mahasiswa · ${p.usia} tahun · '
                        '${p.beratKg.round()} kg',
                        style: const TextStyle(color: AppColors.teksRedup),
                      ),
                      TautanTeks(
                        'Edit profil ›',
                        onTap: () => _buka(context, const EditProfilPage()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            KartuTint(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.targetKustom == null
                              ? 'TARGET AIR EFEKTIF'
                              : 'TARGET AIR · DIATUR MANUAL',
                          style: const TextStyle(
                            color: AppColors.aksen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${formatRibuan(state.targetMl)} ml / hari',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Estimasi awal, bukan anjuran medis. Sesuaikan '
                          'kapan saja.',
                          style: TextStyle(color: AppColors.teksRedup),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TombolKotak(
                    ikon: Icons.edit_outlined,
                    tooltip: 'Ubah target',
                    warnaIkon: AppColors.primary,
                    onTap: () => _ubahTarget(context, state),
                  ),
                ],
              ),
            ),
            const JudulBagian('Rutinitas & pengingat'),
            GrupPengaturan(
              baris: [
                BarisPengaturan(
                  ikon: Icons.wb_twilight,
                  judul: 'Bangun & tidur',
                  keterangan:
                      '${formatMenit(p.jamBangun)}–${formatMenit(p.jamTidur)}'
                      ' · aktivitas ${p.aktivitas.label.toLowerCase()}',
                  kanan: const _Ubah(),
                  onTap: () => _buka(context, const EditProfilPage()),
                ),
                BarisPengaturan(
                  ikon: Icons.notifications_none,
                  judul: 'Pengingat minum',
                  keterangan: p.pengingatAktif
                      ? 'Setiap ${p.intervalMenit} menit di luar jam kuliah'
                      : 'Dimatikan',
                  kanan: Switch(
                    value: p.pengingatAktif,
                    onChanged: (v) => _aturPengingat(context, state, p, v),
                  ),
                ),
                BarisPengaturan(
                  ikon: Icons.dark_mode_outlined,
                  judul: 'Jam tenang',
                  keterangan:
                      '${formatMenit(p.jamTidur - 60)}–'
                      '${formatMenit(p.jamBangun)} · biarkan istirahat',
                  kanan: Switch(
                    value: p.jamTenang,
                    onChanged: (v) =>
                        state.setProfile(p.copyWith(jamTenang: v)),
                  ),
                ),
              ],
            ),
            const JudulBagian('Koneksi & kendali data'),
            KartuPutih(
              padding: EdgeInsets.zero,
              onTap: () => _buka(context, const _IntegrasiPage()),
              child: const Column(
                children: [
                  BarisPengaturan(
                    ikon: Icons.power_outlined,
                    judul: 'Kelola izin & integrasi',
                    keterangan: 'Notifikasi, kalender, kesehatan, lokasi',
                    kanan: Text(
                      'Kelola ›',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: CatatanKecil(
                      'Data pribadi tersimpan di HP. Hanya nama & statistik '
                      'yang dikirim ke leaderboard.',
                      ikon: Icons.verified_user_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GrupPengaturan(
              baris: [
                BarisPengaturan(
                  ikon: Icons.lock_outline,
                  judul: 'Privasi & data pribadi',
                  keterangan: 'Ekspor, data demo, atau hapus datamu',
                  kanan: const _Panah(),
                  onTap: () => _buka(context, const _PrivasiPage()),
                ),
                BarisPengaturan(
                  ikon: Icons.help_outline,
                  judul: 'Pusat bantuan',
                  keterangan: 'Tentang target dan pengingat',
                  kanan: const _Panah(),
                  onTap: () => _bantuan(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'HydroMate · teman kecil untuk kebiasaan baik.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.teksRedup),
            ),
          ],
        ),
      ),
    );
  }

  void _bantuan(BuildContext context) {
    const tanya = [
      (
        'Bagaimana target dihitung?',
        'Berat badan × 33 ml (× 30 ml bila usia di atas 55 tahun), ditambah '
            '300/600 ml untuk aktivitas sedang/tinggi, dan 300 ml saat suhu '
            'Purwokerto ≥ 30°C. Kamu bisa mengubahnya manual.',
      ),
      (
        'Apa itu air efektif?',
        'Tidak semua minuman menghidrasi sama. Air putih dihitung penuh, teh '
            '×0,9, kopi ×0,8, boba ×0,7, dan minuman energi ×0,6.',
      ),
      (
        'Kapan pengingat muncul?',
        'Sesuai interval di jam aktifmu, digeser keluar jam kuliah, ditambah '
            'pengingat 10 menit sebelum kelas. Senyap saat sesi fokus dan '
            'berhenti setelah target tercapai.',
      ),
      (
        'Kenapa ada pengingat yang bergeser sendiri?',
        'Bila pengingat di jam tertentu sering terlewat beberapa minggu, '
            'HydroMate mencarikan celah waktu lain secara otomatis.',
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const Text(
              'Pusat bantuan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final (t, j) in tanya)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                title: Text(
                  t,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  Text(j, style: const TextStyle(color: AppColors.teksRedup)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Ubah extends StatelessWidget {
  const _Ubah();

  @override
  Widget build(BuildContext context) => const Text(
    'Ubah ›',
    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
  );
}

class _Panah extends StatelessWidget {
  const _Panah();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.chevron_right, color: AppColors.primary);
}

// Edit profil memakai form yang sama dengan onboarding
class EditProfilPage extends StatelessWidget {
  const EditProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const BarAtas(judul: 'Edit profil'),
            const SizedBox(height: 18),
            ProfileForm(
              awal: state.profile,
              targetKustomAwal: state.targetKustom,
              labelSimpan: 'Simpan profil',
              onSimpan: (h) {
                state.targetKustom = h.targetKustom;
                state.perbaruiProfil(h.profil);
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Profil disimpan. Target ${formatRibuan(state.targetMl)} ml',
                      ),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegrasiPage extends StatelessWidget {
  const _IntegrasiPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: const [
            BarAtas(judul: 'Izin & integrasi'),
            SizedBox(height: 18),
            DaftarIntegrasi(),
          ],
        ),
      ),
    );
  }
}

class _PrivasiPage extends StatelessWidget {
  const _PrivasiPage();

  Future<bool> _konfirmasi(
    BuildContext context, {
    required String judul,
    required String isi,
    required String aksi,
  }) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(aksi),
          ),
        ],
      ),
    );
    return ya == true;
  }

  void _pesan(BuildContext context, String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _ekspor(BuildContext context) async {
    final state = context.read<AppState>();
    final data = const JsonEncoder.withIndent('  ').convert({
      'profil': state.profile?.toJson(),
      'targetMl': state.targetMl,
      'jadwal': state.schedules.map((e) => e.toJson()).toList(),
      'catatan': state.logs.map((e) => e.toJson()).toList(),
    });
    await Clipboard.setData(ClipboardData(text: data));
    if (context.mounted) {
      _pesan(
        context,
        'Data (${state.logs.length} catatan) disalin sebagai JSON',
      );
    }
  }

  Future<void> _demo(BuildContext context) async {
    final ya = await _konfirmasi(
      context,
      judul: 'Isi data demo?',
      isi:
          'Menambahkan riwayat minum 4 minggu terakhir dan jadwal kuliah '
          'contoh (bila jadwal masih kosong). Data yang ada tidak dihapus.',
      aksi: 'Isi data',
    );
    if (!ya || !context.mounted) return;
    isiDataDemo(context.read<AppState>());
    _pesan(context, 'Data demo ditambahkan');
  }

  Future<void> _reset(BuildContext context) async {
    final ya = await _konfirmasi(
      context,
      judul: 'Hapus semua data?',
      isi: 'Profil, riwayat minum, dan jadwal kuliah akan dihapus permanen.',
      aksi: 'Hapus',
    );
    if (!ya || !context.mounted) return;
    final state = context.read<AppState>();
    // Tutup semua halaman; profil kosong membuat aplikasi kembali ke awal
    Navigator.of(context).popUntil((r) => r.isFirst);
    await state.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const BarAtas(judul: 'Privasi & data'),
            const SizedBox(height: 14),
            const CatatanKecil(
              'Profil, riwayat minum, dan jadwal disimpan hanya di HP ini. '
              'Leaderboard hanya menerima nama panggilan dan statistik.',
              ikon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 18),
            GrupPengaturan(
              baris: [
                BarisPengaturan(
                  ikon: Icons.file_download_outlined,
                  judul: 'Ekspor data',
                  keterangan: 'Salin semua data sebagai JSON',
                  kanan: const _Panah(),
                  onTap: () => _ekspor(context),
                ),
                BarisPengaturan(
                  ikon: Icons.auto_awesome_outlined,
                  judul: 'Isi data demo',
                  keterangan: 'Riwayat 4 minggu + jadwal contoh',
                  kanan: const _Panah(),
                  onTap: () => _demo(context),
                ),
                BarisPengaturan(
                  ikon: Icons.delete_outline,
                  judul: 'Hapus semua data',
                  keterangan: 'Kembali seperti baru dipasang',
                  kanan: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () => _reset(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
