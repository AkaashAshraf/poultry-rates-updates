import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/mode_toggle.dart';
import '../cities/manage_cities_screen.dart';
import '../content/app_content_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../news/manage_news_screen.dart';
import '../rates/manage_rates_screen.dart';
import '../users/admin_users_screen.dart';

/// Admin-only shell: reached from Settings > "Login as Admin" once a phone
/// number has been verified AND that number is on the `admins` allow-list.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    ManageCitiesScreen(),
    ManageRatesScreen(),
    ManageNewsScreen(),
    AdminUsersScreen(),
  ];

  final _titles = const [
    'admin.dashboard',
    'admin.cities',
    'admin.rates',
    'admin.feed',
    'admin.users',
  ];

  Future<void> _logout() async {
    // Captured before the first `await` so we never touch `context` after
    // an async gap without a `mounted` check.
    final authProvider = context.read<AuthProvider>();
    final confirmed = await showConfirmDialog(
      context,
      titleKey: 'admin.logoutTitle',
      messageKey: 'admin.logoutMessage',
      confirmKey: 'admin.logout',
      danger: false,
    );
    if (!confirmed) return;
    await authProvider.signOutAdmin();
    if (!mounted) return;
    context.go(AppRoutes.userHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index].tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'appContent.title'.tr(),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppContentScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'admin.logout'.tr(),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ModeToggle(
              isAdminMode: true,
              onAdminMode: () {},
              onUserMode: () => context.go(AppRoutes.userHome),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: 'admin.dashboard'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_city_outlined),
            selectedIcon: const Icon(Icons.location_city),
            label: 'admin.cities'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: 'admin.rates'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: 'admin.feed'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: 'admin.users'.tr(),
          ),
        ],
      ),
    );
  }
}
