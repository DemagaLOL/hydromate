import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';

// Halaman pertama: isi profil untuk menghitung target minum harian
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _beratCtrl = TextEditingController();
  final _usiaCtrl = TextEditingController();
  Aktivitas _aktivitas = Aktivitas.sedang;

  @override
  void dispose() {
    _beratCtrl.dispose();
    _usiaCtrl.dispose();
    super.dispose();
  }

  // Profil dari input saat ini, null bila belum valid
  UserProfile? get _profilSementara {
    final berat = double.tryParse(_beratCtrl.text.replaceAll(',', '.'));
    final usia = int.tryParse(_usiaCtrl.text);
    if (berat == null || berat <= 0 || usia == null || usia <= 0) return null;
    return UserProfile(beratKg: berat, usia: usia, aktivitas: _aktivitas);
  }

  String? _validasiAngka(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Masukkan angka lebih dari 0';
    return null;
  }

  void _mulai() {
    if (!_formKey.currentState!.validate()) return;
    final p = _profilSementara;
    if (p == null) return;
    final state = context.read<AppState>();
    // Target diset dulu, lalu profil (profil memicu pindah ke HomeShell)
    state.setTarget(hitungTargetHarian(p));
    state.setProfile(p);
  }

  @override
  Widget build(BuildContext context) {
    final p = _profilSementara;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Selamat datang di HydroMate')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Isi profil singkat agar target minummu bisa dihitung.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _beratCtrl,
              decoration: const InputDecoration(
                labelText: 'Berat badan',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validasiAngka,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usiaCtrl,
              decoration: const InputDecoration(
                labelText: 'Usia',
                suffixText: 'tahun',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Masukkan angka bulat' : _validasiAngka(v),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Tingkat aktivitas', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<Aktivitas>(
              segments: const [
                ButtonSegment(value: Aktivitas.rendah, label: Text('Rendah')),
                ButtonSegment(value: Aktivitas.sedang, label: Text('Sedang')),
                ButtonSegment(value: Aktivitas.tinggi, label: Text('Tinggi')),
              ],
              selected: {_aktivitas},
              onSelectionChanged: (s) => setState(() => _aktivitas = s.first),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p == null
                            ? 'Target harian akan muncul di sini'
                            : 'Estimasi target harian: ${hitungTargetHarian(p)} ml',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _mulai,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Mulai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
