import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Konfigurasi Supabase diisi saat build, bukan ditulis di kode:
//   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//               --dart-define=SUPABASE_KEY=<publishable/anon key>
// Tanpa keduanya aplikasi tetap jalan dengan data lokal/contoh.
class SupabaseConfig {
  SupabaseConfig._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_KEY');

  static bool _aktif = false;

  // True bila Supabase terkonfigurasi dan berhasil diinisialisasi
  static bool get aktif => _aktif;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (_url.isEmpty || _key.isEmpty) return;
    try {
      await Supabase.initialize(url: _url, publishableKey: _key);
      _aktif = true;
    } catch (e) {
      debugPrint('Supabase gagal diinisialisasi: $e');
    }
  }

  // Masuk secara anonim (sekali per perangkat, sesi disimpan otomatis)
  static Future<String?> pastikanMasuk() async {
    if (!_aktif) return null;
    final auth = client.auth;
    if (auth.currentUser != null) return auth.currentUser!.id;
    final res = await auth.signInAnonymously();
    return res.user?.id;
  }
}
