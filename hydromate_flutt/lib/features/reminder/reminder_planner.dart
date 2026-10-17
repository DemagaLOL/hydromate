import '../../core/models.dart';

// Jendela pengingat bawaan dalam menit sejak 00.00
const int awalPengingat = 7 * 60; // 07.00
const int akhirPengingat = 21 * 60; // 21.00
const int jedaPengingat = 60; // pengingat rutin tiap 60 menit
const int jedaMinimal = 30; // jarak minimal antar pengingat
const int sebelumKelas = 10; // pengingat "minum dulu" sebelum kelas
const int geserAdaptif = 30; // slot yang sering diabaikan dimundurkan segini

// Waktu pengingat minum (menit sejak 00.00) untuk satu hari, digeser keluar
// jam kuliah. Pengingat sebelum kelas diprioritaskan, lalu pengingat rutin
// ditambahkan bila tidak terlalu dekat dengan pengingat lain. Slot rutin yang
// ada di [diabaikan] dimundurkan agar mencari celah waktu lain.
List<int> hitungWaktuPengingat(
  int hari,
  List<ClassSchedule> jadwal, {
  int awal = awalPengingat,
  int akhir = akhirPengingat,
  Set<int> diabaikan = const {},
  int interval = jedaPengingat,
}) {
  final kelas = jadwal.where((j) => j.hari == hari).toList();

  // Kelas yang sedang berlangsung pada menit m (null bila kosong)
  ClassSchedule? kelasPada(int m) {
    for (final k in kelas) {
      if (m >= k.jamMulai && m < k.jamSelesai) return k;
    }
    return null;
  }

  // Geser ke akhir kelas, berulang bila kelas berikutnya langsung menyambung
  int geserKeluar(int m) {
    var k = kelasPada(m);
    while (k != null) {
      m = k.jamSelesai;
      k = kelasPada(m);
    }
    return m;
  }

  bool dalamJendela(int m) => m >= awal && m <= akhir;

  final hasil = <int>[];
  bool cukupJauh(int m) => hasil.every((h) => (h - m).abs() >= jedaMinimal);

  // 1. Pengingat sebelum kelas (prioritas)
  for (final k in kelas) {
    final m = k.jamMulai - sebelumKelas;
    if (dalamJendela(m) && kelasPada(m) == null && cukupJauh(m)) hasil.add(m);
  }

  // 2. Pengingat rutin, digeser keluar jam kuliah
  for (var c = awal; c <= akhir; c += interval) {
    final m = geserKeluar(
      geserKeluar(c) + (diabaikan.contains(c) ? geserAdaptif : 0),
    );
    if (dalamJendela(m) && cukupJauh(m)) hasil.add(m);
  }

  hasil.sort();
  return hasil;
}

// Slot rutin (titik awal sebelum digeser) yang sering diabaikan: pada minimal
// [ambang] dari [minggu] minggu terakhir di hari yang sama, tidak ada catatan
// minum dalam [jendela] menit setelah pengingat. Hanya hari yang punya catatan
// yang dihitung, agar hari sebelum aplikasi dipakai tidak dianggap diabaikan.
Set<int> slotDiabaikan(
  int hari,
  List<ClassSchedule> jadwal,
  List<DrinkLog> logs, {
  int awal = awalPengingat,
  int akhir = akhirPengingat,
  DateTime? sekarang,
  int minggu = 4,
  int ambang = 3,
  int jendela = 45,
  int interval = jedaPengingat,
}) {
  final hariIni = tanggalSaja(sekarang ?? DateTime.now());

  // Tanggal terakhir sebelum hari ini dengan weekday == hari
  var mundur = (hariIni.weekday - hari) % 7;
  if (mundur == 0) mundur = 7;

  // Menit catatan minum per tanggal yang diperiksa
  final tanggal = [
    for (var w = 0; w < minggu; w++)
      DateTime(hariIni.year, hariIni.month, hariIni.day - mundur - 7 * w),
  ];
  final menitPerTanggal = <DateTime, List<int>>{for (final t in tanggal) t: []};
  for (final l in logs) {
    menitPerTanggal[tanggalSaja(l.waktu)]?.add(
      l.waktu.hour * 60 + l.waktu.minute,
    );
  }

  // Hanya slot yang benar-benar muncul di rencana dasar yang dinilai. Slot di
  // jam kuliah atau yang terbuang karena terlalu dekat pengingat lain dilewati.
  final rencanaDasar = hitungWaktuPengingat(
    hari,
    jadwal,
    awal: awal,
    akhir: akhir,
    interval: interval,
  ).toSet();

  final hasil = <int>{};
  for (var c = awal; c <= akhir; c += interval) {
    if (!rencanaDasar.contains(c)) continue;
    var terlewat = 0;
    for (final menit in menitPerTanggal.values) {
      if (menit.isEmpty) continue;
      final direspons = menit.any((x) => x >= c && x <= c + jendela);
      if (!direspons) terlewat++;
    }
    if (terlewat >= ambang) hasil.add(c);
  }
  return hasil;
}

// Jendela pengingat (menit sejak 00.00) sesuai profil. Saat jam tenang aktif:
// dari jam bangun sampai 1 jam sebelum tidur; saat nonaktif: 06.00–23.00.
({int awal, int akhir}) jendelaPengingat(UserProfile? profil) {
  if (profil == null) return (awal: awalPengingat, akhir: akhirPengingat);
  if (!profil.jamTenang) return (awal: 6 * 60, akhir: 23 * 60);
  return (awal: profil.jamBangun, akhir: profil.jamTidur - 60);
}

// Rencana pengingat satu hari: di dalam jendela pengingat, digeser keluar jam
// kuliah, dan (bila adaptif) menghindari slot yang sering diabaikan
List<int> rencanaPengingat(
  int hari, {
  required UserProfile? profil,
  required List<ClassSchedule> jadwal,
  required List<DrinkLog> logs,
  DateTime? sekarang,
  bool adaptif = true,
}) {
  final (:awal, :akhir) = jendelaPengingat(profil);
  final interval = profil?.intervalMenit ?? jedaPengingat;
  final diabaikan = adaptif
      ? slotDiabaikan(
          hari,
          jadwal,
          logs,
          awal: awal,
          akhir: akhir,
          sekarang: sekarang,
          interval: interval,
        )
      : const <int>{};
  return hitungWaktuPengingat(
    hari,
    jadwal,
    awal: awal,
    akhir: akhir,
    diabaikan: diabaikan,
    interval: interval,
  );
}

// Kelas yang berakhir tepat pada menit [m] di hari tersebut (untuk keterangan
// "setelah kelas selesai")
ClassSchedule? kelasBerakhirPada(int hari, int m, List<ClassSchedule> jadwal) {
  for (final k in jadwal) {
    if (k.hari == hari && k.jamSelesai == m) return k;
  }
  return null;
}

// Kelas yang dimulai tepat [sebelumKelas] menit setelah [m]
ClassSchedule? kelasSetelah(int hari, int m, List<ClassSchedule> jadwal) {
  for (final k in jadwal) {
    if (k.hari == hari && k.jamMulai - sebelumKelas == m) return k;
  }
  return null;
}

// Format menit sejak 00.00, contoh 485 -> "08.05"
String formatMenit(int menit) =>
    '${(menit ~/ 60).toString().padLeft(2, '0')}.${(menit % 60).toString().padLeft(2, '0')}';

// Nama hari, indeks 1 = Senin ... 7 = Minggu
const List<String> namaHari = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
