import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/models.dart';
import '../reminder/reminder_planner.dart';
import '../tracker/drink_style.dart';

// Hasil form profil: profil baru dan target manual (null = otomatis)
typedef HasilProfil = ({UserProfile profil, int? targetKustom});

// Form "Kenali kebutuhanmu": nama, usia, berat, aktivitas, jam bangun/tidur,
// dan estimasi target yang bisa diubah. Dipakai di onboarding dan edit profil.
class ProfileForm extends StatefulWidget {
  final UserProfile? awal;
  final int? targetKustomAwal;
  final String labelSimpan;
  final ValueChanged<HasilProfil> onSimpan;
  // Dipanggil setiap nama berubah (untuk sapaan "Hai, Nadia" di atas form)
  final ValueChanged<String>? onNamaBerubah;

  const ProfileForm({
    super.key,
    this.awal,
    this.targetKustomAwal,
    required this.labelSimpan,
    required this.onSimpan,
    this.onNamaBerubah,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _namaCtrl = TextEditingController(text: widget.awal?.nama ?? '');
  late final _beratCtrl = TextEditingController(
    text: widget.awal == null ? '' : _angka(widget.awal!.beratKg),
  );
  late final _usiaCtrl = TextEditingController(
    text: widget.awal?.usia.toString() ?? '',
  );
  late Aktivitas _aktivitas = widget.awal?.aktivitas ?? Aktivitas.sedang;
  late int _jamBangun = widget.awal?.jamBangun ?? 6 * 60 + 30;
  late int _jamTidur = widget.awal?.jamTidur ?? 22 * 60 + 30;
  late int? _targetKustom = widget.targetKustomAwal;

  // 60.0 -> "60", 60.5 -> "60.5"
  static String _angka(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    _namaCtrl.dispose();
    _beratCtrl.dispose();
    _usiaCtrl.dispose();
    super.dispose();
  }

  // Profil dari input saat ini, null bila belum valid
  UserProfile? get _profilSementara {
    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final usia = int.tryParse(_usiaCtrl.text);
    if (berat == null || berat <= 0 || usia == null || usia <= 0) return null;
    final dasar =
        widget.awal ??
        const UserProfile(beratKg: 1, usia: 1, aktivitas: Aktivitas.sedang);
    return dasar.copyWith(
      nama: _namaCtrl.text.trim(),
      beratKg: berat,
      usia: usia,
      aktivitas: _aktivitas,
      jamBangun: _jamBangun,
      jamTidur: _jamTidur,
    );
  }

  Future<void> _pilihJam(bool bangun) async {
    final menit = bangun ? _jamBangun : _jamTidur;
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: menit ~/ 60, minute: menit % 60),
      helpText: bangun ? 'Jam bangun' : 'Jam tidur',
    );
    if (hasil == null) return;
    final m = hasil.hour * 60 + hasil.minute;
    setState(() => bangun ? _jamBangun = m : _jamTidur = m);
  }

  // Ubah target manual, atau kembali ke hitungan otomatis
  Future<void> _ubahTarget(int otomatis) async {
    final ctrl = TextEditingController(
      text: (_targetKustom ?? otomatis).toString(),
    );
    final hasil = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah target harian'),
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
    setState(() => _targetKustom = hasil == -1 ? null : hasil);
  }

  void _infoTarget() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cara menghitung target'),
        content: const Text(
          'Berat badan × 33 ml (× 30 ml bila usia di atas 55 tahun), '
          'ditambah 300 ml untuk aktivitas sedang atau 600 ml untuk aktivitas '
          'tinggi, dan 300 ml saat suhu di atas 30°C.\n\n'
          'Ini estimasi umum, bukan anjuran medis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final p = _profilSementara;
    if (p == null) return;
    widget.onSimpan((profil: p, targetKustom: _targetKustom));
  }

  @override
  Widget build(BuildContext context) {
    final p = _profilSementara;
    final otomatis = p == null ? null : hitungTargetHarian(p);
    final target = _targetKustom ?? otomatis;
    // Minimal 2 jam antara bangun dan tidur agar ada jendela pengingat
    final jamValid = _jamTidur - _jamBangun >= 120;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('Nama panggilan'),
          TextFormField(
            controller: _namaCtrl,
            textCapitalization: TextCapitalization.words,
            maxLength: 24,
            style: _gayaIsian,
            decoration: const InputDecoration(
              hintText: 'contoh: Nadia',
              counterText: '',
            ),
            validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Minimal 2 karakter' : null,
            onChanged: (v) {
              widget.onNamaBerubah?.call(v.trim());
              setState(() {});
            },
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Usia'),
                    TextFormField(
                      controller: _usiaCtrl,
                      keyboardType: TextInputType.number,
                      style: _gayaIsian,
                      decoration: const InputDecoration(suffixText: 'tahun'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n <= 0 || n > 120
                            ? 'Usia tidak valid'
                            : null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Berat badan'),
                    TextFormField(
                      controller: _beratCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: _gayaIsian,
                      decoration: const InputDecoration(suffixText: 'kg'),
                      validator: (v) {
                        final n = double.tryParse(
                          (v ?? '').replaceAll(',', '.'),
                        );
                        return n == null || n < 20 || n > 300
                            ? 'Berat tidak valid'
                            : null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _Label('Aktivitas harian'),
          SegmenPil<Aktivitas>(
            pilihan: [for (final a in Aktivitas.values) (a, a.label)],
            terpilih: _aktivitas,
            onPilih: (a) => setState(() => _aktivitas = a),
          ),
          const SizedBox(height: 10),
          Text(
            '${_aktivitas.label} · ${_aktivitas.keterangan}',
            style: const TextStyle(color: AppColors.teksRedup),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _KotakJam(
                  label: 'Bangun',
                  menit: _jamBangun,
                  ikon: Icons.wb_sunny,
                  warnaIkon: const Color(0xFFF2B01E),
                  onTap: () => _pilihJam(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KotakJam(
                  label: 'Tidur',
                  menit: _jamTidur,
                  ikon: Icons.nightlight_round,
                  warnaIkon: AppColors.teksRedup,
                  onTap: () => _pilihJam(false),
                ),
              ),
            ],
          ),
          if (!jamValid)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Jam tidur minimal 2 jam setelah jam bangun.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 22),
          // Estimasi target yang berubah langsung saat input diisi
          KartuTint(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _targetKustom == null
                            ? 'ESTIMASI TARGET AWAL'
                            : 'TARGET DIATUR MANUAL',
                        style: const TextStyle(
                          color: AppColors.aksen,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _infoTarget,
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (target == null)
                      const Expanded(
                        child: Text(
                          'Isi usia dan berat untuk melihat target',
                          style: TextStyle(color: AppColors.teksRedup),
                        ),
                      )
                    else ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: target.toDouble()),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, v, _) => Text(
                          formatRibuan(v),
                          style: const TextStyle(
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'ml / hari',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.teksRedup,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _ubahTarget(otomatis ?? target),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Ubah'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Contoh estimasi yang bisa diedit, bukan anjuran medis. '
                  'Kebutuhan dapat berbeda sesuai aktivitas, cuaca, dan '
                  'kondisi tubuh.',
                  style: TextStyle(color: AppColors.teksRedup),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: jamValid ? _simpan : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(widget.labelSimpan),
          ),
          const SizedBox(height: 14),
          const Text(
            'Data ini hanya untuk membantu personalisasi pengingatmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teksRedup, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

const _gayaIsian = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

class _Label extends StatelessWidget {
  final String teks;

  const _Label(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        teks,
        style: const TextStyle(
          color: AppColors.teksRedup,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

// Kotak jam (bangun/tidur) yang membuka pemilih jam saat diketuk
class _KotakJam extends StatelessWidget {
  final String label;
  final int menit;
  final IconData ikon;
  final Color warnaIkon;
  final VoidCallback onTap;

  const _KotakJam({
    required this.label,
    required this.menit,
    required this.ikon,
    required this.warnaIkon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        KartuPutih(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          onTap: onTap,
          child: Row(
            children: [
              Expanded(child: Text(formatMenit(menit), style: _gayaIsian)),
              Icon(ikon, color: warnaIkon, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}
