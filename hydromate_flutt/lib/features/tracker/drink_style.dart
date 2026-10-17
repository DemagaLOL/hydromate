import 'package:flutter/material.dart';

// Warna cairan per jenis minuman
const Map<String, Color> warnaMinuman = {
  'Air putih': Color(0xFF1E6FE0),
  'Teh': Color(0xFFC8873A),
  'Kopi': Color(0xFF6F4E37),
  'Boba': Color(0xFFD9B98C),
  'Energi': Color(0xFFF2C230),
};

// Ikon per jenis minuman
const Map<String, IconData> ikonMinuman = {
  'Air putih': Icons.water_drop,
  'Teh': Icons.emoji_food_beverage,
  'Kopi': Icons.coffee,
  'Boba': Icons.bubble_chart,
  'Energi': Icons.bolt,
};

Color warnaDari(String jenis) => warnaMinuman[jenis] ?? const Color(0xFF1E6FE0);
IconData ikonDari(String jenis) => ikonMinuman[jenis] ?? Icons.local_drink;

// Format angka dengan pemisah ribuan titik, contoh 1240 -> "1.240"
String formatRibuan(num v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

// Format jam, contoh 08.05
String formatJam(DateTime w) =>
    '${w.hour.toString().padLeft(2, '0')}.${w.minute.toString().padLeft(2, '0')}';
