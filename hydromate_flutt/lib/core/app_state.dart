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

  // Log yang dicatat hari ini
  List<DrinkLog> get logsHariIni {
    final now = DateTime.now();
    return logs
        .where((l) =>
            l.waktu.year == now.year &&
            l.waktu.month == now.month &&
            l.waktu.day == now.day)
        .toList();
  }

  // Total air efektif (ml x koefisien) dari log hari ini
  double get airEfektifHariIni =>
      logsHariIni.fold(0.0, (total, l) => total + l.mlEfektif);

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

  void addLog(DrinkLog log) {
    logs.add(log);
    _ubah();
  }

  void addSchedule(ClassSchedule schedule) {
    schedules.add(schedule);
    _ubah();
  }

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
      final profilBaru =
          p == null ? null : UserProfile.fromJson(p as Map<String, dynamic>);
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
    };
    await _prefs.setString(_kunciSimpan, jsonEncode(data));
  }
}
