import 'package:flutter/material.dart';

import '../../core/models.dart';
import 'reminder_planner.dart';

// Bottom sheet tambah jadwal kuliah. Mengembalikan jadwal baru atau null.
Future<ClassSchedule?> showScheduleFormSheet(
  BuildContext context, {
  required int hariAwal,
  required List<ClassSchedule> jadwalAda,
}) {
  return showModalBottomSheet<ClassSchedule>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FormJadwal(hariAwal: hariAwal, jadwalAda: jadwalAda),
  );
}

class _FormJadwal extends StatefulWidget {
  final int hariAwal;
  final List<ClassSchedule> jadwalAda;

  const _FormJadwal({required this.hariAwal, required this.jadwalAda});

  @override
  State<_FormJadwal> createState() => _FormJadwalState();
}

class _FormJadwalState extends State<_FormJadwal> {
  final _nama = TextEditingController();
  late int _hari = widget.hariAwal;
  TimeOfDay _mulai = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _selesai = const TimeOfDay(hour: 9, minute: 40);

  int get _menitMulai => _mulai.hour * 60 + _mulai.minute;
  int get _menitSelesai => _selesai.hour * 60 + _selesai.minute;

  // Jadwal lain di hari yang sama yang waktunya bertabrakan
  ClassSchedule? get _bentrok {
    for (final j in widget.jadwalAda) {
      if (j.hari == _hari &&
          _menitMulai < j.jamSelesai &&
          j.jamMulai < _menitSelesai) {
        return j;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _pilihJam(bool mulai) async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: mulai ? _mulai : _selesai,
      helpText: mulai ? 'Jam mulai' : 'Jam selesai',
    );
    if (hasil == null) return;
    setState(() => mulai ? _mulai = hasil : _selesai = hasil);
  }

  void _simpan() {
    Navigator.pop(
      context,
      ClassSchedule(
        nama: _nama.text.trim(),
        hari: _hari,
        jamMulai: _menitMulai,
        jamSelesai: _menitSelesai,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final valid = _menitSelesai > _menitMulai;
    final bentrok = _bentrok;

    return Padding(
      // Geser ke atas saat keyboard muncul
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tambah jadwal kuliah', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Mata kuliah',
              hintText: 'contoh: Kalkulus',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _hari,
            decoration: const InputDecoration(labelText: 'Hari'),
            items: [
              for (var h = 1; h <= 7; h++)
                DropdownMenuItem(value: h, child: Text(namaHari[h])),
            ],
            onChanged: (v) => setState(() => _hari = v ?? _hari),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('Mulai ${formatMenit(_menitMulai)}'),
                  onPressed: () => _pilihJam(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('Selesai ${formatMenit(_menitSelesai)}'),
                  onPressed: () => _pilihJam(false),
                ),
              ),
            ],
          ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Jam selesai harus setelah jam mulai.',
                style: TextStyle(color: scheme.error),
              ),
            )
          else if (bentrok != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Bentrok dengan ${bentrok.nama.isEmpty ? 'jadwal lain' : bentrok.nama} '
                '(${formatMenit(bentrok.jamMulai)}–${formatMenit(bentrok.jamSelesai)}).',
                style: TextStyle(color: scheme.tertiary),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: valid ? _simpan : null,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
