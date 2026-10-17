import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../focus/pomodoro_timer.dart';
import 'reminder_planner.dart';

// Notifikasi pengingat minum lokal (Android saja).
// Pengingat dijadwalkan bergulir untuk 7 hari ke depan dan dipasang ulang
// setiap kali rencananya berubah atau aplikasi dibuka kembali.
class ReminderService {
  ReminderService._();

  static const _hariKeDepan = 7;
  static const _idTes = 9999;
  static const _idFokus = 9000;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _siap = false;

  static AppState? _state;
  static String? _tandaTanganTerakhir;
  static Timer? _debounce;
  static Future<void>? _sedangJalan;
  // ignore: unused_field
  static AppLifecycleListener? _lifecycle;

  static const _detail = NotificationDetails(
    android: AndroidNotificationDetails(
      'pengingat_minum',
      'Pengingat minum',
      channelDescription: 'Pengingat minum air di luar jam kuliah',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static bool get _didukung =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Siapkan zona waktu dan plugin notifikasi
  static Future<void> init() async {
    if (!_didukung || _siap) return;
    try {
      tz_data.initializeTimeZones();
      // Target pengguna di Purwokerto (WIB)
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      // Izin notifikasi diminta di onboarding / saat masuk beranda (mintaIzin)
      _siap = true;
    } catch (e) {
      debugPrint('Gagal menyiapkan notifikasi: $e');
    }
  }

  // Pantau state: pasang ulang pengingat bila jadwal, profil, status target,
  // atau pola minum berubah, dan setiap kali aplikasi kembali dibuka
  static void pantau(AppState state) {
    _state = state;
    state.addListener(_jadwalkanNanti);
    _lifecycle = AppLifecycleListener(onResume: _jadwalkanNanti);
    _jadwalkanNanti();
  }

  static void _jadwalkanNanti() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _sedangJalan = (_sedangJalan ?? Future.value()).then((_) => _jadwalkan());
    });
  }

  static Future<void> _jadwalkan() async {
    final state = _state;
    if (!_siap || state == null) return;

    final rencana = _rencana(state);
    final tandaTangan = jsonEncode(
      rencana.map((r) => [r.waktu.toIso8601String(), r.pesan]).toList(),
    );
    if (tandaTangan == _tandaTanganTerakhir) return;

    try {
      // Batalkan pengingat lama (selain notifikasi fokus/tes)
      final tertunda = await _plugin.pendingNotificationRequests();
      for (final n in tertunda) {
        if (n.id < _idFokus) await _plugin.cancel(id: n.id);
      }
      for (var i = 0; i < rencana.length; i++) {
        await _plugin.zonedSchedule(
          id: i,
          scheduledDate: rencana[i].waktu,
          notificationDetails: _detail,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Waktunya minum 💧',
          body: rencana[i].pesan,
        );
      }
      _tandaTanganTerakhir = tandaTangan;
    } catch (e) {
      debugPrint('Gagal menjadwalkan pengingat: $e');
    }
  }

  // Daftar pengingat 7 hari ke depan. Kosong bila profil belum ada.
  // Hari ini dilewati bila target sudah tercapai.
  static List<({tz.TZDateTime waktu, String pesan})> _rencana(AppState state) {
    final profil = state.profile;
    if (profil == null || !profil.pengingatAktif) return const [];
    final now = tz.TZDateTime.now(tz.local);
    // Pengingat senyap selama sesi fokus berjalan
    final senyap = _senyapSampai;
    final hasil = <({tz.TZDateTime waktu, String pesan})>[];

    for (var offset = 0; offset < _hariKeDepan; offset++) {
      if (offset == 0 && state.targetTercapaiHariIni) continue;
      final tgl = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + offset,
      );
      final menitList = rencanaPengingat(
        tgl.weekday,
        profil: profil,
        jadwal: state.schedules,
        logs: state.logs,
        sekarang: tgl,
      );
      for (final m in menitList) {
        final w = tz.TZDateTime(
          tz.local,
          tgl.year,
          tgl.month,
          tgl.day,
          m ~/ 60,
          m % 60,
        );
        if (!w.isAfter(now)) continue;
        if (senyap != null && w.isBefore(senyap)) continue;
        hasil.add((waktu: w, pesan: _pesan(tgl.weekday, m, state.schedules)));
      }
    }
    return hasil;
  }

  static DateTime? _senyapSampai;
  static DateTime? _akhirFokusTerjadwal;

  // Pantau timer Pomodoro: jadwalkan notifikasi akhir fase dan senyapkan
  // pengingat minum selama sesi fokus berjalan
  static void pantauFokus(PomodoroTimer timer) {
    timer.addListener(() {
      final akhir = timer.berakhirPada;
      if (akhir != _akhirFokusTerjadwal) {
        _akhirFokusTerjadwal = akhir;
        if (akhir == null) {
          batalkanFokus();
        } else {
          jadwalkanFokus(akhir, fokus: timer.fase == FasePomodoro.fokus);
        }
      }
      final senyap = timer.fase == FasePomodoro.fokus ? akhir : null;
      if (senyap != _senyapSampai) {
        _senyapSampai = senyap;
        _jadwalkanNanti();
      }
    });
  }

  // Minta izin notifikasi (Android 13+); true bila diizinkan
  static Future<bool> mintaIzin() async {
    if (!_siap) return false;
    final ok = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return ok ?? false;
  }

  // Notifikasi akhir fase Pomodoro, agar tetap muncul saat app di background
  static Future<void> jadwalkanFokus(
    DateTime akhir, {
    required bool fokus,
  }) async {
    if (!_siap) return;
    try {
      await _plugin.zonedSchedule(
        id: _idFokus,
        scheduledDate: tz.TZDateTime.from(akhir, tz.local),
        notificationDetails: _detail,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: fokus ? 'Sesi fokus selesai 🎉' : 'Istirahat selesai',
        body: fokus
            ? 'Waktunya istirahat: berdiri, regangkan otot, dan minum 💧'
            : 'Siap fokus lagi? Buka HydroMate untuk mulai sesi berikutnya.',
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi fokus: $e');
    }
  }

  static Future<void> batalkanFokus() async {
    if (!_siap) return;
    await _plugin.cancel(id: _idFokus);
  }

  // Notifikasi percobaan 5 detik lagi, untuk demo
  static Future<bool> tesNotifikasi() async {
    if (!_siap) return false;
    try {
      await _plugin.zonedSchedule(
        id: _idTes,
        scheduledDate: tz.TZDateTime.now(tz.local)
            .add(const Duration(seconds: 5)),
        notificationDetails: _detail,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Waktunya minum 💧',
        body: 'Ini contoh pengingat HydroMate.',
      );
      return true;
    } catch (e) {
      debugPrint('Gagal tes notifikasi: $e');
      return false;
    }
  }

  // Pesan khusus bila pengingat tepat sebelum kelas atau setelah kelas
  static String _pesan(int hari, int menit, List<ClassSchedule> jadwal) {
    for (final k in jadwal) {
      if (k.hari != hari) continue;
      final nama = k.nama.isEmpty ? 'kelas' : k.nama;
      if (k.jamMulai - sebelumKelas == menit) {
        return 'Minum dulu sebelum $nama jam ${formatMenit(k.jamMulai)}.';
      }
      if (k.jamSelesai == menit) {
        return '$nama selesai, saatnya isi ulang cairan tubuh.';
      }
    }
    return 'Yuk minum segelas air sekarang.';
  }
}
