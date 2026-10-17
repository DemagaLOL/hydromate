import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

// Komponen UI bersama yang mengikuti desain HydroMate

const _namaBulan = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _namaHariPanjang = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String namaBulan(int bulan) => _namaBulan[bulan];

// "Senin, 19 Oktober"
String tanggalPanjang(DateTime d) =>
    '${_namaHariPanjang[d.weekday]}, ${d.day} ${_namaBulan[d.month]}';

// Info fitur yang belum tersedia (integrasi di roadmap)
void segeraHadir(BuildContext context, String fitur) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$fitur segera hadir di versi berikutnya.')),
    );
}

// Logo HydroMate: kotak gradien berisi tetes air tersenyum dan riak air
class HydroLogo extends StatelessWidget {
  final double ukuran;

  const HydroLogo({super.key, this.ukuran = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: ukuran,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final kotak = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.24),
    );
    canvas.drawRRect(
      kotak,
      Paint()..shader = AppColors.gradien.createShader(Offset.zero & size),
    );

    // Riak air di bawah tetes
    final riak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..color = Colors.white.withValues(alpha: 0.35);
    final pusatRiak = Offset(s * 0.5, s * 0.83);
    canvas.drawOval(
      Rect.fromCenter(center: pusatRiak, width: s * 0.62, height: s * 0.13),
      riak,
    );
    canvas.drawOval(
      Rect.fromCenter(center: pusatRiak, width: s * 0.42, height: s * 0.08),
      riak,
    );

    // Tetes air putih
    final cx = s * 0.5;
    final atas = s * 0.17;
    final bawah = s * 0.72;
    final lebar = s * 0.24;
    final tetes = Path()
      ..moveTo(cx, atas)
      ..cubicTo(
        cx + lebar * 0.25,
        atas + s * 0.12,
        cx + lebar * 1.2,
        bawah - s * 0.26,
        cx + lebar * 1.1,
        bawah - s * 0.15,
      )
      ..arcToPoint(
        Offset(cx - lebar * 1.1, bawah - s * 0.15),
        radius: Radius.circular(lebar * 1.12),
      )
      ..cubicTo(
        cx - lebar * 1.2,
        bawah - s * 0.26,
        cx - lebar * 0.25,
        atas + s * 0.12,
        cx,
        atas,
      )
      ..close();
    canvas.drawPath(tetes, Paint()..color = Colors.white);

    // Wajah tersenyum
    final wajah = Paint()..color = const Color(0xFF1C8FC4);
    final yMata = s * 0.52;
    canvas.drawCircle(Offset(cx - s * 0.07, yMata), s * 0.025, wajah);
    canvas.drawCircle(Offset(cx + s * 0.07, yMata), s * 0.025, wajah);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, s * 0.58),
        width: s * 0.16,
        height: s * 0.09,
      ),
      0.2,
      2.74,
      false,
      Paint()
        ..color = const Color(0xFF1C8FC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.022
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

// Avatar lingkaran berisi inisial nama
class AvatarInisial extends StatelessWidget {
  final String nama;
  final double ukuran;
  final VoidCallback? onTap;
  final bool kotak;

  const AvatarInisial({
    super.key,
    required this.nama,
    this.ukuran = 52,
    this.onTap,
    this.kotak = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = kotak ? ukuran * 0.3 : ukuran / 2;
    return Material(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: SizedBox.square(
          dimension: ukuran,
          child: Center(
            child: Text(
              inisial(nama),
              style: TextStyle(
                color: AppColors.aksen,
                fontWeight: FontWeight.w900,
                fontSize: ukuran * 0.34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tombol kotak putih dengan ikon (mis. kembali)
class TombolKotak extends StatelessWidget {
  final IconData ikon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? warnaIkon;

  const TombolKotak({
    super.key,
    required this.ikon,
    this.onTap,
    this.tooltip,
    this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    final tombol = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radiusTombol),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusTombol),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 56,
          child: Icon(ikon, color: warnaIkon ?? AppColors.teks),
        ),
      ),
    );
    return tooltip == null ? tombol : Tooltip(message: tooltip, child: tombol);
  }
}

// Baris atas halaman: tombol kembali / logo, judul, dan elemen kanan
class BarAtas extends StatelessWidget {
  final String judul;
  final bool kembali;
  final bool logo;
  final Widget? kanan;

  const BarAtas({
    super.key,
    required this.judul,
    this.kembali = true,
    this.logo = false,
    this.kanan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (kembali)
            TombolKotak(
              ikon: Icons.chevron_left,
              tooltip: 'Kembali',
              onTap: () => Navigator.maybePop(context),
            )
          else if (logo)
            const HydroLogo(ukuran: 52),
          const SizedBox(width: 16),
          // Judul panjang diperkecil agar tetap utuh di layar sempit
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                judul,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (kanan != null) ...[const SizedBox(width: 8), kanan!],
        ],
      ),
    );
  }
}

// Tautan teks biru tebal ("Lihat semua", "Ubah ›")
class TautanTeks extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color warna;

  const TautanTeks(
    this.label, {
    super.key,
    this.onTap,
    this.warna = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: warna,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// Label pil kecil berhuruf kapital ("SESUAI RITMEMU", "SESI 1 DARI 4")
class PilLabel extends StatelessWidget {
  final String teks;
  final IconData? ikon;
  final Color warna;
  final Color latar;
  final bool kapital;

  const PilLabel(
    this.teks, {
    super.key,
    this.ikon,
    this.warna = AppColors.aksen,
    this.latar = AppColors.tint,
    this.kapital = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 17, color: warna),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              kapital ? teks.toUpperCase() : teks,
              style: TextStyle(
                color: warna,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: kapital ? 0.4 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kartu berwarna lembut tanpa garis
class KartuTint extends StatelessWidget {
  final Widget child;
  final Color warna;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const KartuTint({
    super.key,
    required this.child,
    this.warna = AppColors.tint,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: warna,
      borderRadius: BorderRadius.circular(radiusKartu),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusKartu),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// Kartu putih bergaris tipis
class KartuPutih extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? garis;

  const KartuPutih({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.garis,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusKartu),
        side: BorderSide(color: garis ?? AppColors.garis, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusKartu),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// Ikon di dalam kotak tint bersudut
class IkonKotak extends StatelessWidget {
  final IconData ikon;
  final double ukuran;
  final Color warna;
  final Color latar;

  const IkonKotak(
    this.ikon, {
    super.key,
    this.ukuran = 52,
    this.warna = AppColors.primary,
    this.latar = AppColors.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(ukuran * 0.3),
      ),
      child: Icon(ikon, color: warna, size: ukuran * 0.5),
    );
  }
}

// Kontrol segmen bergaya pil: lintasan tint, pilihan aktif putih
class SegmenPil<T> extends StatelessWidget {
  final List<(T, String)> pilihan;
  final T terpilih;
  final ValueChanged<T>? onPilih;

  const SegmenPil({
    super.key,
    required this.pilihan,
    required this.terpilih,
    this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(radiusTombol),
      ),
      child: Row(
        children: [
          for (final (nilai, label) in pilihan)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPilih == null ? null : () => onPilih!(nilai),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: nilai == terpilih ? Colors.white : null,
                    borderRadius: BorderRadius.circular(radiusTombol - 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: nilai == terpilih
                          ? AppColors.primary
                          : AppColors.teksRedup,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Satu baris di kartu pengaturan: ikon, judul, keterangan, elemen kanan
class BarisPengaturan extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String? keterangan;
  final Widget? kanan;
  final VoidCallback? onTap;

  const BarisPengaturan({
    super.key,
    required this.ikon,
    required this.judul,
    this.keterangan,
    this.kanan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            IkonKotak(ikon, ukuran: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (keterangan != null)
                    Text(
                      keterangan!,
                      style: const TextStyle(color: AppColors.teksRedup),
                    ),
                ],
              ),
            ),
            if (kanan != null) ...[const SizedBox(width: 8), kanan!],
          ],
        ),
      ),
    );
  }
}

// Kartu putih berisi beberapa BarisPengaturan dipisah garis
class GrupPengaturan extends StatelessWidget {
  final List<Widget> baris;

  const GrupPengaturan({super.key, required this.baris});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusKartu),
        side: const BorderSide(color: AppColors.garis, width: 1.2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < baris.length; i++) ...[
            if (i > 0) const Divider(indent: 18, endIndent: 18),
            baris[i],
          ],
        ],
      ),
    );
  }
}

// Teks catatan kecil dengan ikon info di kiri
class CatatanKecil extends StatelessWidget {
  final String teks;
  final IconData ikon;
  final bool tengah;

  const CatatanKecil(
    this.teks, {
    super.key,
    this.ikon = Icons.info_outline,
    this.tengah = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: tengah
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            teks,
            style: const TextStyle(color: AppColors.teksRedup, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
