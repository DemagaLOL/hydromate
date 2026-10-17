import 'dart:convert';

import 'package:http/http.dart' as http;

// Suhu saat ini (°C) di area Unsoed Purwokerto dari Open-Meteo.
// Mengembalikan null bila gagal (offline, timeout, format berubah).
Future<double?> ambilSuhuSekarang() async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '-7.43',
    'longitude': '109.25',
    'current': 'temperature_2m',
  });
  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    return (current?['temperature_2m'] as num?)?.toDouble();
  } catch (_) {
    return null;
  }
}
