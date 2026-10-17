import 'package:flutter/material.dart';

import '../features/map/map_page.dart';
import '../features/reminder/reminder_service.dart';
import '../features/social/social_page.dart';
import '../features/tracker/stats_page.dart';
import '../features/tracker/tracker_page.dart';
import 'theme.dart';

// Kerangka utama dengan bottom navigation 4 tab. Jadwal, Fokus, Catat, dan
// Profil dibuka sebagai halaman terpisah dari tab-tab ini.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Minta izin notifikasi sekali saat masuk beranda (bila belum)
    ReminderService.mintaIzin();
  }

  void _ke(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack agar state tiap tab tidak hilang saat berpindah
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            TrackerPage(onLihatStatistik: () => _ke(1)),
            const StatsPage(),
            const SocialPage(),
            const MapPage(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.garis)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _ke,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Statistik',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Teman',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Isi ulang',
            ),
          ],
        ),
      ),
    );
  }
}
