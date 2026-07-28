import 'package:flutter/material.dart';

import '../../../widgets/banner_ad_slot.dart';
import '../rates/rates_screen.dart';

/// The public-facing app. Temporarily simplified down to just the Rates
/// screen — Feed, Graphs and the bottom nav bar are hidden for now
/// (Settings is still reachable via the icon on Rates' own AppBar; see
/// rates_screen.dart). The tab/nav code isn't deleted, just unused, so
/// it's a quick revert to bring News/Graphs back:
///   - restore the NavigationBar + IndexedStack that used to live here
///     (see git history), and
///   - re-enable the interstitial ad triggers that used to live in this
///     file's initState/_onDestinationSelected — also removed for now
///     per "hide video ad" — InterstitialAdService itself is untouched,
///     it's just never called.
class UserShellScreen extends StatelessWidget {
  const UserShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RatesScreen(),
      // Banner ad only — the interstitial ("video") ad is disabled for now
      // by simply never calling InterstitialAdService.maybeShow().
      bottomNavigationBar: BannerAdSlot(),
    );
  }
}
