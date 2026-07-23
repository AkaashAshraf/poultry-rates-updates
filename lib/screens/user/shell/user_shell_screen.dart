import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../feed/news_feed_screen.dart';
import '../rates/rates_screen.dart';
import '../graphs/graphs_screen.dart';
import '../settings/user_settings_screen.dart';

/// The public-facing app: four tabs, no login required. This is exactly
/// what item 1 of the "user flavor" spec asks for — browsing works with
/// zero credentials.
class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _index = 0;

  final _screens = const [
    NewsFeedScreen(),
    RatesScreen(),
    GraphsScreen(),
    UserSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: 'nav.feed'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: 'nav.rates'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart),
            label: 'nav.graphs'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: 'nav.settings'.tr(),
          ),
        ],
      ),
    );
  }
}
