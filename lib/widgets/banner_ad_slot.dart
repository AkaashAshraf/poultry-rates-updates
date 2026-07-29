import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants/ad_constants.dart';

/// A bottom-of-screen banner ad, placed once in UserShellScreen so it's
/// loaded a single time and persists across tab switches, rather than each
/// of the four tabs loading (and paying for) its own ad.
///
/// Uses an anchored *adaptive* banner sized to the full device width
/// (`AdSize.getLargeAnchoredAdaptiveBannerAdSize`) instead of the fixed
/// 320x50 banner, so the ad always spans edge-to-edge like the nav bar
/// above it, on any phone/tablet width.
///
/// Renders as zero-height until the ad actually loads, and again if it
/// fails to load — so a slow network or an unfilled ad request never
/// leaves a dead gap or shifts the layout.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs MediaQuery (for the device width), which isn't available yet in
    // initState — request the ad the first time dependencies are ready, and
    // never again (avoids re-requesting on every rebuild/rotation).
    if (!_requested) {
      _requested = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final unitId = AdConstants.bannerAdUnitId;
    if (unitId == null) return; // Unsupported platform (e.g. web) — no ads.

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
