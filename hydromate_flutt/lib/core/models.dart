// Koefisien hidrasi per jenis minuman (nilai estimasi)
const Map<String, double> koefisienHidrasi = {
  'Air putih': 1.0,
  'Teh': 0.9,
  'Kopi': 0.8,
  'Boba': 0.7,
  'Energi': 0.6,
};

// Tingkat aktivitas harian pengguna
enum Aktivitas { rendah, sedang, tinggi }

// Profil dasar pengguna untuk menghitung target minum
class UserProfile {
  final String nama; // nama panggilan, untuk sapaan dan leaderboard
  final double beratKg;
  final int usia;
  final Aktivitas aktivitas;
  final int jamBangun; // menit sejak 00.00, awal jendela pengingat
  final int jamTidur; // menit sejak 00.00
  final int intervalMenit; // jarak pengingat rutin saat tidak ada kelas
  final bool jamTenang; // tanpa pengingat di luar jam bangun-tidur
  final bool pengingatAktif; // saklar utama notifikasi pengingat

  const UserProfile({
    this.nama = '',
    required this.beratKg,
    required this.usia,
    required this.aktivitas,
    this.jamBangun = 7 * 60,
    this.jamTidur = 22 * 60,
    this.intervalMenit = 60,
    this.jamTenang = true,
    this.pengingatAktif = true,
  });

  UserProfile copyWith({
    String? nama,
    double? beratKg,
    int? usia,
    Aktivitas? aktivitas,
    int? jamBangun,
    int? jamTidur,
    int? intervalMenit,
    bool? jamTenang,
    bool? pengingatAktif,
  }) => UserProfile(
    nama: nama ?? this.nama,
    beratKg: beratKg ?? this.beratKg,
    usia: usia ?? this.usia,
    aktivitas: aktivitas ?? this.aktivitas,
    jamBangun: jamBangun ?? this.jamBangun,
    jamTidur: jamTidur ?? this.jamTidur,
    intervalMenit: intervalMenit ?? this.intervalMenit,
    jamTenang: jamTenang ?? this.jamTenang,
    pengingatAktif: pengingatAktif ?? this.pengingatAktif,
  );

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'beratKg': beratKg,
    'usia': usia,
    'aktivitas': aktivitas.name,
    'jamBangun': jamBangun,
    'jamTidur': jamTidur,
    'intervalMenit': intervalMenit,
    'jamTenang': jamTenang,
    'pengingatAktif': pengingatAktif,
  };

  // Field selain berat/usia/aktivitas opsional agar data lama tetap terbaca
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    nama: json['nama'] as String? ?? '',
    beratKg: (json['beratKg'] as num).toDouble(),
    usia: json['usia'] as int,
    aktivitas: Aktivitas.values.byName(json['aktivitas'] as String),
    jamBangun: json['jamBangun'] as int? ?? 7 * 60,
    jamTidur: json['jamTidur'] as int? ?? 22 * 60,
    intervalMenit: json['intervalMenit'] as int? ?? 60,
    jamTenang: json['jamTenang'] as bool? ?? true,
    pengingatAktif: json['pengingatAktif'] as bool? ?? true,
  );
}

// Label dan keterangan tingkat aktivitas (dipakai di form profil)
extension AktivitasInfo on Aktivitas {
  String get label => switch (this) {
    Aktivitas.rendah => 'Ringan',
    Aktivitas.sedang => 'Sedang',
    Aktivitas.tinggi => 'Tinggi',
  };

  String get keterangan => switch (this) {
    Aktivitas.rendah => 'banyak duduk, jarang berjalan jauh.',
    Aktivitas.sedang => 'jalan antarkelas dan olahraga ringan.',
    Aktivitas.tinggi => 'olahraga rutin atau aktivitas fisik berat.',
  };
}

// Inisial nama untuk avatar, contoh "Nadia Aulia" -> "NA", "Dana" -> "DA"
String inisial(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
  if (kata.isEmpty) return '?';
  if (kata.length == 1) {
    final k = kata.first;
    return (k.length >= 2 ? k.substring(0, 2) : k).toUpperCase();
  }
  return (kata.first[0] + kata.elementAt(1)[0]).toUpperCase();
}

// Target harian (ml) = berat x 33 (x 30 bila usia > 55) + bonus aktivitas
// + bonus suhu >= 30C
int hitungTargetHarian(UserProfile p, {double? suhuC}) {
  final mlPerKg = p.usia > 55 ? 30 : 33;
  final bonusAktivitas = switch (p.aktivitas) {
    Aktivitas.rendah => 0,
    Aktivitas.sedang => 300,
    Aktivitas.tinggi => 600,
  };
  final bonusSuhu = (suhuC != null && suhuC >= 30) ? 300 : 0;
  return (p.beratKg * mlPerKg).round() + bonusAktivitas + bonusSuhu;
}

// Tanggal tanpa jam
DateTime tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);

// Total air efektif per tanggal
Map<DateTime, double> totalEfektifPerTanggal(List<DrinkLog> logs) {
  final total = <DateTime, double>{};
  for (final l in logs) {
    final k = tanggalSaja(l.waktu);
    total[k] = (total[k] ?? 0) + l.mlEfektif;
  }
  return total;
}

// Total air efektif n hari terakhir, urut dari yang terlama sampai hari ini
List<double> totalEfektifPerHari(
  List<DrinkLog> logs,
  int n, {
  DateTime? sekarang,
}) {
  final total = totalEfektifPerTanggal(logs);
  final hariIni = tanggalSaja(sekarang ?? DateTime.now());
  return [
    for (var i = n - 1; i >= 0; i--)
      total[DateTime(hariIni.year, hariIni.month, hariIni.day - i)] ?? 0,
  ];
}

// Jumlah hari berturut-turut target tercapai. Dihitung mundur dari hari ini,
// atau dari kemarin bila target hari ini belum tercapai (agar pagi hari tidak 0)
int hitungStreak(List<DrinkLog> logs, int targetMl, {DateTime? sekarang}) {
  final totalPerHari = totalEfektifPerTanggal(logs);
  bool tercapai(DateTime d) => (totalPerHari[d] ?? 0) >= targetMl;

  var hari = tanggalSaja(sekarang ?? DateTime.now());
  if (!tercapai(hari)) hari = DateTime(hari.year, hari.month, hari.day - 1);
  var streak = 0;
  while (tercapai(hari)) {
    streak++;
    hari = DateTime(hari.year, hari.month, hari.day - 1);
  }
  return streak;
}

// Satu catatan minum
class DrinkLog {
  final String jenis; // kunci dari koefisienHidrasi
  final int ml;
  final DateTime waktu;

  const DrinkLog({required this.jenis, required this.ml, required this.waktu});

  // Air efektif = ml x koefisien (default 1.0 bila jenis tidak dikenal)
  double get mlEfektif => ml * (koefisienHidrasi[jenis] ?? 1.0);

  Map<String, dynamic> toJson() => {
    'jenis': jenis,
    'ml': ml,
    'waktu': waktu.toIso8601String(),
  };

  factory DrinkLog.fromJson(Map<String, dynamic> json) => DrinkLog(
    jenis: json['jenis'] as String,
    ml: json['ml'] as int,
    waktu: DateTime.parse(json['waktu'] as String),
  );
}

// Jadwal kuliah mingguan
class ClassSchedule {
  final String nama; // nama mata kuliah
  final int hari; // 1 = Senin ... 7 = Minggu (sama dengan DateTime.weekday)
  final int jamMulai; // menit sejak 00.00
  final int jamSelesai; // menit sejak 00.00

  const ClassSchedule({
    this.nama = '',
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'hari': hari,
    'jamMulai': jamMulai,
    'jamSelesai': jamSelesai,
  };

  // 'nama' opsional agar data lama (tanpa nama) tetap terbaca
  factory ClassSchedule.fromJson(Map<String, dynamic> json) => ClassSchedule(
    nama: json['nama'] as String? ?? '',
    hari: json['hari'] as int,
    jamMulai: json['jamMulai'] as int,
    jamSelesai: json['jamSelesai'] as int,
  );
}
