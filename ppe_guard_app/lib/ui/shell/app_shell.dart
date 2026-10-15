import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../services/realtime_service.dart';
import '../../services/refresh_signal.dart';
import '../screens/alerts_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  static const _pages = <Widget>[
    DashboardScreen(),
    HistoryScreen(),
    AlertsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  static const _destinations = <_Destination>[
    _Destination('ภาพรวม', Icons.grid_view_rounded, Icons.grid_view_rounded),
    _Destination('ประวัติ', Icons.history_outlined, Icons.history),
    _Destination('แจ้งเตือน', Icons.notifications_none_rounded, Icons.notifications_rounded),
    _Destination('รายงาน', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _Destination('โปรไฟล์', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.connect();
    _subscription = RealtimeService.instance.events.listen((_) => RefreshSignal.publish());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  void _changePage(int value) {
    if (value == _index) return;
    setState(() {
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final content = IndexedStack(index: _index, children: _pages);
        if (!wide) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _changePage,
              destinations: _destinations
                  .map((item) => NavigationDestination(icon: Icon(item.outlined), selectedIcon: Icon(item.filled), label: item.label))
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: Container(
                  width: constraints.maxWidth >= 1240 ? 242 : 84,
                  margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(26), border: Border.all(color: AppPalette.line)),
                  child: NavigationRail(
                    selectedIndex: _index,
                    labelType: constraints.maxWidth >= 1240 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                    extended: constraints.maxWidth >= 1240,
                    minExtendedWidth: 220,
                    groupAlignment: -0.65,
                    onDestinationSelected: _changePage,
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(7, 6, 7, 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: AppPalette.navy, borderRadius: BorderRadius.circular(13)),
                            child: const Icon(Icons.health_and_safety_outlined, color: Colors.white),
                          ),
                          if (constraints.maxWidth >= 1240) ...[
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PPE Guard', style: TextStyle(fontWeight: FontWeight.w900, color: AppPalette.ink)),
                                Text('Site monitoring', style: TextStyle(fontSize: 11, color: AppPalette.mutedInk)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: _destinations
                        .map((item) => NavigationRailDestination(icon: Icon(item.outlined), selectedIcon: Icon(item.filled), label: Text(item.label)))
                        .toList(),
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.label, this.outlined, this.filled);

  final String label;
  final IconData outlined;
  final IconData filled;
}
