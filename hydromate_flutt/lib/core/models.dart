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
  final double beratKg;
  final int usia;
  final Aktivitas aktivitas;

  const UserProfile({
    required this.beratKg,
    required this.usia,
    required this.aktivitas,
  });

  Map<String, dynamic> toJson() => {
        'beratKg': beratKg,
        'usia': usia,
        'aktivitas': aktivitas.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        beratKg: (json['beratKg'] as num).toDouble(),
        usia: json['usia'] as int,
        aktivitas: Aktivitas.values.byName(json['aktivitas'] as String),
      );
}

// Target harian (ml) = berat x 33 + bonus aktivitas + bonus suhu >= 30C
int hitungTargetHarian(UserProfile p, {double? suhuC}) {
  final bonusAktivitas = switch (p.aktivitas) {
    Aktivitas.rendah => 0,
    Aktivitas.sedang => 300,
    Aktivitas.tinggi => 600,
  };
  final bonusSuhu = (suhuC != null && suhuC >= 30) ? 300 : 0;
  return (p.beratKg * 33).round() + bonusAktivitas + bonusSuhu;
}

// Jumlah hari berturut-turut target tercapai. Dihitung mundur dari hari ini,
// atau dari kemarin bila target hari ini belum tercapai (agar pagi hari tidak 0)
int hitungStreak(List<DrinkLog> logs, int targetMl, {DateTime? sekarang}) {
  DateTime tanggal(DateTime d) => DateTime(d.year, d.month, d.day);

  final totalPerHari = <DateTime, double>{};
  for (final l in logs) {
    final k = tanggal(l.waktu);
    totalPerHari[k] = (totalPerHari[k] ?? 0) + l.mlEfektif;
  }
  bool tercapai(DateTime d) => (totalPerHari[d] ?? 0) >= targetMl;

  var hari = tanggal(sekarang ?? DateTime.now());
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
  final int hari; // 1 = Senin ... 7 = Minggu (sama dengan DateTime.weekday)
  final int jamMulai; // menit sejak 00.00
  final int jamSelesai; // menit sejak 00.00

  const ClassSchedule({
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  Map<String, dynamic> toJson() => {
        'hari': hari,
        'jamMulai': jamMulai,
        'jamSelesai': jamSelesai,
      };

  factory ClassSchedule.fromJson(Map<String, dynamic> json) => ClassSchedule(
        hari: json['hari'] as int,
        jamMulai: json['jamMulai'] as int,
        jamSelesai: json['jamSelesai'] as int,
      );
}
