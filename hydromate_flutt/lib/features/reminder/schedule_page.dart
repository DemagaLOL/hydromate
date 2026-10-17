import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../tracker/drink_style.dart';
import 'reminder_planner.dart';
import 'reminder_service.dart';
import 'schedule_form_sheet.dart';

// Halaman "Jadwal cerdas": timeline kelas, pengingat, dan catatan minum per
// hari, plus pengaturan ritme pengingat
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  static Future<void> buka(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SchedulePage()),
  );

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

// Jenis item di timeline
enum _JenisItem { minum, kelas, pengingat }

class _Item {
  final _JenisItem jenis;
  final int mulai; // menit sejak 00.00
  final int? selesai;
  final String judul;
  final String isi;
  final ClassSchedule? kelas;
  final bool lewat;
  final bool berikutnya;
  final bool digeser;
  final bool sedangKelas;

  const _Item({
    required this.jenis,
    required this.mulai,
    this.selesai,
    required this.judul,
    required this.isi,
    this.kelas,
    this.lewat = false,
    this.berikutnya = false,
    this.digeser = false,
    this.sedangKelas = false,
  });
}

class _SchedulePageState extends State<SchedulePage> {
  // 0 = hari ini, 1 = besok, dst. (7 hari ke depan)
  int _offset = 0;

  DateTime get _tanggal {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + _offset);
  }

  Future<void> _tambah() async {
    final state = context.read<AppState>();
    final baru = await showScheduleFormSheet(
      context,
      hariAwal: _tanggal.weekday,
      jadwalAda: state.schedules,
    );
    if (baru == null || !mounted) return;
    // Pengingat dipasang ulang otomatis oleh ReminderService.pantau
    state.addSchedule(baru);
    final now = DateTime.now();
    setState(() => _offset = (baru.hari - now.weekday) % 7);
  }

  Future<void> _hapus(ClassSchedule j) async {
    final state = context.read<AppState>();
    final ya = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: Text(
          '${j.nama.isEmpty ? 'Kelas' : j.nama}, ${namaHari[j.hari]} '
          '${formatMenit(j.jamMulai)}–${formatMenit(j.jamSelesai)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    state.removeSchedule(j);
  }

  Future<void> _pilihInterval(UserProfile p) async {
    final hasil = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Interval pengingat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            for (final m in const [30, 45, 60, 90, 120])
              ListTile(
                title: Text('$m menit'),
                trailing: m == p.intervalMenit
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    context.read<AppState>().setProfile(p.copyWith(intervalMenit: hasil));
  }

  Future<void> _tes() async {
    final ok = await ReminderService.tesNotifikasi();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Notifikasi contoh muncul dalam ±5 detik'
                : 'Notifikasi hanya tersedia di Android',
          ),
        ),
      );
  }

  // Susun item timeline untuk tanggal terpilih
  List<_Item> _susunItem(AppState state) {
    final tgl = _tanggal;
    final hari = tgl.weekday;
    final now = DateTime.now();
    final hariIni = _offset == 0;
    final menitSekarang = hariIni ? now.hour * 60 + now.minute : -1;

    final pengingat = rencanaPengingat(
      hari,
      profil: state.profile,
      jadwal: state.schedules,
      logs: state.logs,
      sekarang: tgl,
    );
    final dasar = rencanaPengingat(
      hari,
      profil: state.profile,
      jadwal: state.schedules,
      logs: state.logs,
      adaptif: false,
    ).toSet();
    final aktif =
        (state.profile?.pengingatAktif ?? true) &&
        !(hariIni && state.targetTercapaiHariIni);
    final berikutnya = aktif
        ? pengingat.where((m) => m > menitSekarang).firstOrNull
        : null;

    final item = <_Item>[
      // Catatan minum (hanya hari ini)
      if (hariIni)
        for (final l in state.logsHariIni)
          _Item(
            jenis: _JenisItem.minum,
            mulai: l.waktu.hour * 60 + l.waktu.minute,
            judul: '${l.jenis} tercatat',
            isi:
                '${formatRibuan(l.ml)} ml'
                '${l.jenis == 'Air putih' ? '' : ' · ≈ ${formatRibuan(l.mlEfektif)} ml efektif'}',
          ),
      for (final k in state.schedules.where((j) => j.hari == hari))
        _Item(
          jenis: _JenisItem.kelas,
          mulai: k.jamMulai,
          selesai: k.jamSelesai,
          judul: k.nama.isEmpty ? 'Kuliah' : k.nama,
          isi: menitSekarang >= k.jamMulai && menitSekarang < k.jamSelesai
              ? 'Sedang kelas · pengingat senyap'
              : 'Pengingat senyap saat kelas',
          kelas: k,
          lewat: menitSekarang >= k.jamSelesai,
          sedangKelas:
              menitSekarang >= k.jamMulai && menitSekarang < k.jamSelesai,
        ),
      if (aktif)
        for (final m in pengingat)
          _Item(
            jenis: _JenisItem.pengingat,
            mulai: m,
            judul: m == berikutnya ? 'Jeda untuk minum' : 'Pengingat minum',
            isi: _alasan(hari, m, state.schedules, !dasar.contains(m)),
            lewat: m <= menitSekarang,
            berikutnya: m == berikutnya,
            digeser: !dasar.contains(m),
          ),
    ]..sort((a, b) => a.mulai.compareTo(b.mulai));
    return item;
  }

  static String _alasan(
    int hari,
    int m,
    List<ClassSchedule> jadwal,
    bool digeser,
  ) {
    if (kelasBerakhirPada(hari, m, jadwal) != null) {
      return 'Saran 250 ml · setelah kelas';
    }
    if (kelasSetelah(hari, m, jadwal) != null) {
      return 'Saran 250 ml · sebelum kelas';
    }
    if (digeser) return 'Digeser karena sering terlewat';
    return 'Saran 250 ml';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profil = state.profile;
    final tgl = _tanggal;
    final item = _susunItem(state);
    final jumlahKelas = state.schedules.where((j) => j.hari == tgl.weekday);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            BarAtas(
              judul: 'Jadwal cerdas',
              kanan: AvatarInisial(nama: profil?.nama ?? ''),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanggalPanjang(tgl),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${jumlahKelas.length} kelas · diatur manual',
                        style: const TextStyle(color: AppColors.teksRedup),
                      ),
                    ],
                  ),
                ),
                TombolKotak(
                  ikon: Icons.add,
                  tooltip: 'Tambah jadwal kuliah',
                  warnaIkon: AppColors.primary,
                  onTap: _tambah,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _StripTanggal(
              offset: _offset,
              onPilih: (o) => setState(() => _offset = o),
            ),
            const SizedBox(height: 16),
            KartuTint(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Calendar belum terhubung',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Untuk sekarang, tambahkan jadwal kuliah manual '
                              'lewat tombol +.',
                              style: TextStyle(color: AppColors.teksRedup),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teksRedup,
                    ),
                    onPressed: () =>
                        segeraHadir(context, 'Integrasi Google Calendar'),
                    child: const Text('Segera hadir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (item.isEmpty)
              KartuPutih(
                onTap: _tambah,
                child: const Column(
                  children: [
                    Icon(Icons.event_note, size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada jadwal di hari ini',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Ketuk untuk menambahkan jadwal kuliah',
                      style: TextStyle(color: AppColors.teksRedup),
                    ),
                  ],
                ),
              )
            else
              for (final (i, it) in item.indexed)
                _BarisTimeline(
                  item: it,
                  terakhir: i == item.length - 1,
                  onTap: it.kelas == null ? null : () => _hapus(it.kelas!),
                ),
            if (profil != null) ...[
              const JudulBagian('Atur ritmemu'),
              GrupPengaturan(
                baris: [
                  BarisPengaturan(
                    ikon: Icons.timer_outlined,
                    judul: 'Interval pengingat',
                    keterangan: 'Saat tidak ada jadwal sibuk',
                    kanan: Text(
                      '${profil.intervalMenit} menit ›',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => _pilihInterval(profil),
                  ),
                  BarisPengaturan(
                    ikon: Icons.dark_mode_outlined,
                    judul: 'Jam tenang',
                    keterangan:
                        '${formatMenit(profil.jamTidur - 60)}–'
                        '${formatMenit(profil.jamBangun)} · tanpa pengingat',
                    kanan: Switch(
                      value: profil.jamTenang,
                      onChanged: (v) =>
                          state.setProfile(profil.copyWith(jamTenang: v)),
                    ),
                  ),
                  BarisPengaturan(
                    ikon: Icons.notifications_active_outlined,
                    judul: 'Coba notifikasi',
                    keterangan: 'Kirim contoh pengingat dalam 5 detik',
                    kanan: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                    onTap: _tes,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Deretan 7 hari ke depan untuk memilih tanggal
class _StripTanggal extends StatelessWidget {
  final int offset;
  final ValueChanged<int> onPilih;

  const _StripTanggal({required this.offset, required this.onPilih});

  static const _singkat = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (context) {
                final d = DateTime(now.year, now.month, now.day + i);
                final aktif = i == offset;
                return GestureDetector(
                  onTap: () => onPilih(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: aktif ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: aktif ? AppColors.primary : AppColors.garis,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _singkat[d.weekday],
                          style: TextStyle(
                            fontSize: 12,
                            color: aktif ? Colors.white : AppColors.teksRedup,
                          ),
                        ),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: aktif ? Colors.white : AppColors.teks,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// Satu baris timeline: jam di kiri, titik & garis, lalu kartu
class _BarisTimeline extends StatelessWidget {
  final _Item item;
  final bool terakhir;
  final VoidCallback? onTap;

  const _BarisTimeline({
    required this.item,
    required this.terakhir,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final it = item;
    final (latar, warnaTeks, ikon, warnaTitik) = switch (it.jenis) {
      _JenisItem.minum => (
        Colors.white,
        AppColors.teks,
        Icons.check,
        AppColors.secondary,
      ),
      _JenisItem.kelas => (
        AppColors.tint,
        AppColors.teks,
        it.sedangKelas
            ? Icons.notifications_off_outlined
            : Icons.menu_book_outlined,
        AppColors.teksRedup,
      ),
      _JenisItem.pengingat when it.berikutnya => (
        AppColors.primary,
        Colors.white,
        Icons.water_drop_outlined,
        AppColors.primary,
      ),
      _JenisItem.pengingat => (
        Colors.white,
        AppColors.teks,
        it.digeser ? Icons.auto_fix_high : Icons.water_drop_outlined,
        AppColors.garis,
      ),
    };

    return Opacity(
      opacity: it.lewat && !it.berikutnya ? 0.55 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 54,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMenit(it.mulai),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (it.selesai != null)
                      Text(
                        formatMenit(it.selesai!),
                        style: const TextStyle(color: AppColors.teksRedup),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: warnaTitik,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!terakhir)
                    Expanded(
                      child: Container(width: 2, color: AppColors.garis),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: latar,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusKartu),
                    side: latar == Colors.white
                        ? const BorderSide(color: AppColors.garis)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radiusKartu),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            ikon,
                            color: it.berikutnya
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.judul,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: warnaTeks,
                                  ),
                                ),
                                Text(
                                  it.isi,
                                  style: TextStyle(
                                    color: it.berikutnya
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.teksRedup,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
