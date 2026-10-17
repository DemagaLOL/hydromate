import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../app/ui.dart';
import '../../core/app_state.dart';
import '../profile/settings_page.dart';
import '../tracker/catat_page.dart';
import 'refill_data.dart';

// Tab Isi ulang: peta titik isi ulang air minum di kampus
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _peta = MapController();
  List<TitikRefill> _titik = titikBawaan;
  TitikRefill? _dipilih;
  JenisRefill? _filter;
  bool _hanyaGratis = false;

  @override
  void initState() {
    super.initState();
    muatTitikRefill().then((t) {
      if (mounted) setState(() => _titik = t);
    });
  }

  @override
  void dispose() {
    _peta.dispose();
    super.dispose();
  }

  List<TitikRefill> get _tampil => _titik
      .where((t) => _filter == null || t.jenis == _filter)
      .where((t) => !_hanyaGratis || t.gratis)
      .toList();

  void _pilih(TitikRefill t) {
    HapticFeedback.selectionClick();
    setState(() => _dipilih = t);
    _peta.move(t.posisi, 18);
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.select<AppState, String>((s) => s.profile?.nama ?? '');
    final tampil = _tampil;
    // Titik terpilih harus lolos filter; selain itu pakai titik pertama
    final dipilih = tampil.contains(_dipilih) ? _dipilih : tampil.firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        BarAtas(
          judul: 'Isi ulang di sekitarmu',
          kembali: false,
          logo: true,
          kanan: AvatarInisial(
            nama: nama,
            onTap: () => SettingsPage.buka(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.my_location, color: AppColors.primary),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi belum diizinkan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    'Menampilkan titik di sekitar kampus Unsoed.',
                    style: TextStyle(color: AppColors.teksRedup),
                  ),
                ],
              ),
            ),
            TautanTeks(
              'Segera hadir',
              warna: AppColors.teksRedup,
              onTap: () => segeraHadir(context, 'Izin lokasi'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Gratis'),
                avatar: const Icon(Icons.savings_outlined, size: 18),
                selected: _hanyaGratis,
                onSelected: (v) => setState(() => _hanyaGratis = v),
              ),
              for (final j in JenisRefill.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(j.label),
                  avatar: Icon(j.ikon, size: 18, color: j.warna),
                  selected: _filter == j,
                  onSelected: (v) => setState(() => _filter = v ? j : null),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 340,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _peta,
                  options: const MapOptions(
                    initialCenter: pusatKampus,
                    initialZoom: 16.5,
                    minZoom: 13,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.hydromate_flutt',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final t in tampil)
                          Marker(
                            point: t.posisi,
                            width: 60,
                            height: 70,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => _pilih(t),
                              child: _Pin(
                                titik: t,
                                aktif: identical(t, dipilih),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Atribusi wajib OSM
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      popupInitialDisplayDuration: Duration(seconds: 3),
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: PilLabel(
                    'Peta kampus Unsoed',
                    latar: Colors.white,
                    warna: AppColors.teksRedup,
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: TombolKotak(
                    ikon: Icons.gps_fixed,
                    tooltip: 'Kembali ke kampus',
                    warnaIkon: AppColors.primary,
                    onTap: () => _peta.move(pusatKampus, 16.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: dipilih == null
              ? const KartuPutih(
                  key: ValueKey('kosong'),
                  child: Text(
                    'Tidak ada titik untuk filter ini.',
                    textAlign: TextAlign.center,
                  ),
                )
              : _DetailTitik(key: ValueKey(dipilih.nama), titik: dipilih),
        ),
        if (tampil.length > 1) ...[
          const JudulBagian('Titik lainnya'),
          for (final t in tampil.where((t) => !identical(t, dipilih)))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KartuPutih(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                onTap: () => _pilih(t),
                child: Row(
                  children: [
                    IkonKotak(
                      t.jenis.ikon,
                      ukuran: 44,
                      warna: t.jenis.warna,
                      latar: t.jenis.warna.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.nama,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${t.jenis.label} · ${t.jamBuka}',
                            style: const TextStyle(color: AppColors.teksRedup),
                          ),
                        ],
                      ),
                    ),
                    _LabelHarga(gratis: t.gratis),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// Pin peta: kotak membulat berisi tetes air, dengan tangkai kecil di bawah
class _Pin extends StatelessWidget {
  final TitikRefill titik;
  final bool aktif;

  const _Pin({required this.titik, required this.aktif});

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? AppColors.primary : AppColors.aksen;
    return AnimatedScale(
      scale: aktif ? 1.2 : 0.95,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: warna,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: warna.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(titik.jenis.ikon, color: Colors.white, size: 22),
          ),
          Container(width: 4, height: 12, color: warna),
        ],
      ),
    );
  }
}

class _LabelHarga extends StatelessWidget {
  final bool gratis;

  const _LabelHarga({required this.gratis});

  @override
  Widget build(BuildContext context) {
    return PilLabel(
      gratis ? 'Gratis' : 'Berbayar',
      kapital: false,
      warna: gratis ? AppColors.sukses : const Color(0xFFD9822B),
      latar: gratis ? const Color(0xFFE5F6EC) : AppColors.hangat,
    );
  }
}

class _DetailTitik extends StatelessWidget {
  final TitikRefill titik;

  const _DetailTitik({super.key, required this.titik});

  @override
  Widget build(BuildContext context) {
    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PilLabel(
                'Tersedia · ${titik.gratis ? 'gratis' : 'berbayar'}',
                ikon: Icons.check,
                kapital: false,
              ),
              const Spacer(),
              Text(
                titik.jamBuka,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            titik.nama,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${titik.jenis.label} · ${titik.keterangan}',
            style: const TextStyle(color: AppColors.teksRedup, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => bukaCatat(context, lokasi: titik.nama),
            icon: const Icon(Icons.local_drink_outlined),
            label: const Text('Catat isi ulang di sini'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => segeraHadir(context, 'Rute jalan kaki'),
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Lihat rute jalan kaki · segera hadir'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Koordinat perkiraan. Cek kondisi di lokasi sebelum mengisi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teksRedup, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
