import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/app_state.dart';
import '../../core/supabase_config.dart';

// Satu baris di leaderboard
class EntriPeringkat {
  final String id;
  final String nama;
  final int streak;
  final int persenHariIni;
  final int mlMingguIni;
  final bool saya;

  const EntriPeringkat({
    required this.id,
    required this.nama,
    required this.streak,
    required this.persenHariIni,
    required this.mlMingguIni,
    this.saya = false,
  });

  // Poin peringkat = persen target hari ini, maksimal 100
  int get poin => persenHariIni.clamp(0, 100);

  factory EntriPeringkat.dariBaris(Map<String, dynamic> r, String? idSaya) =>
      EntriPeringkat(
        id: r['id'] as String,
        nama: r['nama'] as String? ?? '-',
        streak: r['streak'] as int? ?? 0,
        persenHariIni: r['persen_hari_ini'] as int? ?? 0,
        mlMingguIni: r['ml_minggu_ini'] as int? ?? 0,
        saya: r['id'] == idSaya,
      );
}

// Urutkan: streak terpanjang, lalu progres hari ini, lalu total minggu ini
// Urutan: persentase target pribadi hari ini (maksimal 100, minum berlebih
// tidak menambah poin), lalu streak, lalu total minggu ini
List<EntriPeringkat> urutkanPeringkat(Iterable<EntriPeringkat> data) =>
    data.toList()..sort((a, b) {
      final p = b.poin.compareTo(a.poin);
      if (p != 0) return p;
      final s = b.streak.compareTo(a.streak);
      if (s != 0) return s;
      return b.mlMingguIni.compareTo(a.mlMingguIni);
    });

// Kode grup acak 6 karakter (tanpa huruf/angka yang mirip: O/0, I/1)
String buatKodeGrup([math.Random? acak]) {
  const huruf = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = acak ?? math.Random.secure();
  return List.generate(6, (_) => huruf[r.nextInt(huruf.length)]).join();
}

bool kodeGrupValid(String kode) => RegExp(r'^[A-Z0-9]{6}$').hasMatch(kode);

// Akses leaderboard di Supabase (tabel profil_sosial, lihat supabase/schema.sql)
class SocialService {
  SocialService._();

  static const _tabel = 'profil_sosial';

  static bool get online => SupabaseConfig.aktif;

  static String? get idSaya =>
      online ? SupabaseConfig.client.auth.currentUser?.id : null;

  // Kirim statistik terbaru milik pengguna ini
  static Future<void> sinkron(AppState s) async {
    final nama = s.profile?.nama.trim() ?? '';
    if (!online || nama.length < 2) return;
    try {
      final id = await SupabaseConfig.pastikanMasuk();
      if (id == null) return;
      await SupabaseConfig.client.from(_tabel).upsert({
        'id': id,
        'nama': nama.length > 24 ? nama.substring(0, 24) : nama,
        'kode_grup': s.kodeGrup,
        'streak': s.streakHari,
        'persen_hari_ini': s.persenHariIni,
        'ml_minggu_ini': s.mlMingguIni,
        'diperbarui': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Gagal sinkron leaderboard: $e');
    }
  }

  // Leaderboard realtime: anggota grup tertentu, atau 50 teratas semua kampus
  static Stream<List<EntriPeringkat>> pantau({String? kodeGrup}) async* {
    await SupabaseConfig.pastikanMasuk();
    final dasar = SupabaseConfig.client.from(_tabel).stream(primaryKey: ['id']);
    final aliran = kodeGrup != null
        ? dasar.eq('kode_grup', kodeGrup)
        : dasar.order('streak').limit(50);
    yield* aliran.map(
      (rows) => urutkanPeringkat(
        rows.map((r) => EntriPeringkat.dariBaris(r, idSaya)),
      ),
    );
  }

  // Cek apakah grup dengan kode ini sudah punya anggota
  static Future<bool> grupAda(String kode) async {
    if (!online) return true;
    try {
      await SupabaseConfig.pastikanMasuk();
      final rows = await SupabaseConfig.client
          .from(_tabel)
          .select('id')
          .eq('kode_grup', kode)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return true; // jangan blokir pengguna bila jaringan bermasalah
    }
  }
}

// Data contoh untuk mode offline / Supabase belum dikonfigurasi
List<EntriPeringkat> dataContoh(AppState s, {required bool grup}) {
  const teman = [
    ('Raflyanno', 9, 82, 17800),
    ('Devania', 7, 95, 16900),
    ('Noval', 5, 64, 15100),
    ('Pradipta', 4, 100, 14800),
    ('Salsa', 3, 45, 12300),
    ('Bima', 2, 70, 11800),
    ('Aulia', 1, 30, 9600),
  ];
  final kampus = [
    ('Hydro Hero FT', 21, 88, 21500),
    ('Nadia FISIP', 14, 76, 19800),
    ('Arif FEB', 12, 91, 19100),
    ('Putri FK', 10, 60, 18200),
  ];
  final sumber = grup ? teman : [...kampus, ...teman];
  final nama = s.profile?.nama.trim() ?? '';
  return urutkanPeringkat([
    for (final (n, st, p, ml) in sumber)
      EntriPeringkat(
        id: n,
        nama: n,
        streak: st,
        persenHariIni: p,
        mlMingguIni: ml,
      ),
    EntriPeringkat(
      id: 'saya',
      nama: nama.isEmpty ? 'Kamu' : nama,
      streak: s.streakHari,
      persenHariIni: s.persenHariIni,
      mlMingguIni: s.mlMingguIni,
      saya: true,
    ),
  ]);
}
