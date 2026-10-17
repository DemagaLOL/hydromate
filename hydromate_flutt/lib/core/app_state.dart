import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// State global aplikasi, disimpan lokal sebagai JSON di shared_preferences
class AppState extends ChangeNotifier {
  static const _kunciSimpan = 'hydromate_state';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  UserProfile? profile;
  int targetMl = 2000;
  List<DrinkLog> logs = [];
  List<ClassSchedule> schedules = [];

  // Suhu terakhir dari layanan cuaca (tidak disimpan)
  double? suhuTerakhir;

  // Log yang dicatat hari ini, urut dari yang terlama
  List<DrinkLog> get logsHariIni {
    final now = DateTime.now();
    return logs
        .where(
          (l) =>
              l.waktu.year == now.year &&
              l.waktu.month == now.month &&
              l.waktu.day == now.day,
        )
        .toList()
      ..sort((a, b) => a.waktu.compareTo(b.waktu));
  }

  // Total air efektif (ml x koefisien) dari log hari ini
  double get airEfektifHariIni =>
      logsHariIni.fold(0.0, (total, l) => total + l.mlEfektif);

  // Sisa air putih yang perlu diminum agar target hari ini tercapai
  double get sisaAirPutih =>
      (targetMl - airEfektifHariIni).clamp(0, double.infinity).toDouble();

  // Tambahan air putih yang dibutuhkan akibat minuman non-air hari ini
  double get tambahanDariMinumanLain =>
      logsHariIni.fold(0.0, (total, l) => total + (l.ml - l.mlEfektif));

  bool get targetTercapaiHariIni => airEfektifHariIni >= targetMl;

  // Hari berturut-turut target tercapai
  int get streakHari => hitungStreak(logs, targetMl);

  void setProfile(UserProfile value) {
    profile = value;
    _ubah();
  }

  void setTarget(int ml) {
    targetMl = ml;
    _ubah();
  }

  // Target yang diatur manual pengguna (null = dihitung otomatis)
  int? targetKustom;

  // Hitung ulang target: pakai target manual bila ada, selain itu rumus
  // berdasarkan profil dan suhu terakhir
  void perbaruiTarget() {
    final p = profile;
    if (p == null) return;
    setTarget(targetKustom ?? hitungTargetHarian(p, suhuC: suhuTerakhir));
  }

  void setTargetKustom(int? ml) {
    targetKustom = ml;
    perbaruiTarget();
  }

  // Ubah profil sekaligus hitung ulang target
  void perbaruiProfil(UserProfile p) {
    profile = p;
    perbaruiTarget();
  }

  void addLog(DrinkLog log) {
    logs.add(log);
    _ubah();
  }

  void removeLog(DrinkLog log) {
    logs.remove(log);
    _ubah();
  }

  // Tambah banyak log sekaligus (dipakai untuk data demo)
  void addLogs(Iterable<DrinkLog> baru) {
    logs.addAll(baru);
    _ubah();
  }

  // Hapus semua data; profil kosong membuat aplikasi kembali ke onboarding
  Future<void> reset() async {
    profile = null;
    targetMl = 2000;
    logs = [];
    schedules = [];
    kodeGrup = null;
    targetKustom = null;
    await _prefs.remove(_kunciSimpan);
    notifyListeners();
  }

  void addSchedule(ClassSchedule schedule) {
    schedules.add(schedule);
    _ubah();
  }

  void removeSchedule(ClassSchedule schedule) {
    schedules.remove(schedule);
    _ubah();
  }

  // Kode grup leaderboard (null bila belum bergabung)
  String? kodeGrup;

  void setKodeGrup(String? kode) {
    kodeGrup = kode;
    _ubah();
  }

  // Total air efektif 7 hari terakhir, untuk leaderboard
  int get mlMingguIni =>
      totalEfektifPerHari(logs, 7).fold(0.0, (a, b) => a + b).round();

  int get persenHariIni =>
      targetMl <= 0 ? 0 : (airEfektifHariIni / targetMl * 100).round();

  // Beri tahu listener lalu simpan ke penyimpanan lokal
  void _ubah() {
    notifyListeners();
    save();
  }

  Future<void> load() async {
    final raw = await _prefs.getString(_kunciSimpan);
    if (raw == null) return;
    try {
      // Parse ke variabel lokal dulu agar state tidak setengah terisi bila gagal
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final p = data['profile'];
      final profilBaru = p == null
          ? null
          : UserProfile.fromJson(p as Map<String, dynamic>);
      final targetBaru = data['targetMl'] as int? ?? targetMl;
      final logsBaru = (data['logs'] as List? ?? [])
          .map((e) => DrinkLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final schedulesBaru = (data['schedules'] as List? ?? [])
          .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
          .toList();

      profile = profilBaru;
      targetMl = targetBaru;
      logs = logsBaru;
      schedules = schedulesBaru;
      kodeGrup = data['kodeGrup'] as String?;
      targetKustom = data['targetKustom'] as int?;
    } catch (e) {
      // Data rusak: abaikan dan mulai dari kondisi awal
      debugPrint('Gagal memuat state: $e');
    }
    notifyListeners();
  }

  Future<void> save() async {
    final data = {
      'profile': profile?.toJson(),
      'targetMl': targetMl,
      'logs': logs.map((e) => e.toJson()).toList(),
      'schedules': schedules.map((e) => e.toJson()).toList(),
      'kodeGrup': kodeGrup,
      'targetKustom': targetKustom,
    };
    await _prefs.setString(_kunciSimpan, jsonEncode(data));
  }
}
