import 'dart:async';

import 'package:flutter/foundation.dart';

enum FasePomodoro { fokus, istirahat }

// Logika timer Pomodoro. Sisa waktu dihitung dari jam akhir (bukan menghitung
// tick) agar tetap akurat walau tick terlambat.
class PomodoroTimer extends ChangeNotifier {
  PomodoroTimer({
    this.durasiFokus = const Duration(minutes: 25),
    this.durasiIstirahat = const Duration(minutes: 5),
    DateTime Function()? jam,
  })  : _jam = jam ?? DateTime.now,
        sisa = durasiFokus;

  Duration durasiFokus;
  Duration durasiIstirahat;
  final DateTime Function() _jam;

  FasePomodoro fase = FasePomodoro.fokus;
  Duration sisa;
  int sesiSelesai = 0;

  // Dipanggil setiap kali fase berganti (untuk getar, sheet istirahat, dll.)
  void Function(FasePomodoro faseBaru)? onFaseBerubah;

  DateTime? _berakhirPada;
  Timer? _ticker;

  bool get berjalan => _berakhirPada != null;

  Duration get durasiFase =>
      fase == FasePomodoro.fokus ? durasiFokus : durasiIstirahat;

  // 0..1, seberapa jauh fase saat ini sudah berjalan
  double get progres {
    final total = durasiFase.inMilliseconds;
    if (total <= 0) return 0;
    return (1 - sisa.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void mulai() {
    if (berjalan) return;
    _berakhirPada = _jam().add(sisa);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    notifyListeners();
  }

  void jeda() {
    if (!berjalan) return;
    sisa = _hitungSisa();
    _hentikanTicker();
    notifyListeners();
  }

  // Kembali ke awal sesi fokus
  void ulang() {
    _hentikanTicker();
    fase = FasePomodoro.fokus;
    sisa = durasiFokus;
    notifyListeners();
  }

  // Lewati fase saat ini (sesi fokus yang dilewati tidak dihitung)
  void lewati() => _pindahFase(dihitung: false);

  void aturDurasi(Duration fokus, Duration istirahat) {
    durasiFokus = fokus;
    durasiIstirahat = istirahat;
    ulang();
  }

  @visibleForTesting
  void tick() {
    if (!berjalan) return;
    final s = _hitungSisa();
    if (s <= Duration.zero) {
      _pindahFase(dihitung: true);
    } else {
      sisa = s;
      notifyListeners();
    }
  }

  // Fokus -> istirahat langsung berjalan; istirahat -> fokus menunggu "Mulai"
  void _pindahFase({required bool dihitung}) {
    if (fase == FasePomodoro.fokus) {
      if (dihitung) sesiSelesai++;
      fase = FasePomodoro.istirahat;
      sisa = durasiIstirahat;
      if (berjalan) _berakhirPada = _jam().add(sisa);
    } else {
      fase = FasePomodoro.fokus;
      sisa = durasiFokus;
      _hentikanTicker();
    }
    notifyListeners();
    onFaseBerubah?.call(fase);
  }

  Duration _hitungSisa() {
    final s = _berakhirPada!.difference(_jam());
    return s.isNegative ? Duration.zero : s;
  }

  void _hentikanTicker() {
    _ticker?.cancel();
    _ticker = null;
    _berakhirPada = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

// Format mm:ss, dibulatkan ke atas agar tidak tampil 00:00 sebelum selesai
String formatSisa(Duration d) {
  final detik = (d.inMilliseconds / 1000).ceil();
  final m = (detik ~/ 60).toString().padLeft(2, '0');
  final s = (detik % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
