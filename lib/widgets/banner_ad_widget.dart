import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}
class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (!AdService.supported) return;
    _ad = AdService.instance.createBanner(
      onLoaded: () { if (mounted) setState(() => _loaded = true); },
      onFailed: () { if (mounted) setState(() => _loaded = false); },
    );
  }
  @override
  void dispose() { _ad?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => !AdService.supported ? const SizedBox.shrink() : SizedBox(
    height: AdSize.banner.height.toDouble(),
    width: double.infinity,
    child: _loaded && _ad != null ? Center(
      child: SizedBox(width: _ad!.size.width.toDouble(), height: _ad!.size.height.toDouble(), child: AdWidget(ad: _ad!)),
    ) : const SizedBox.shrink(),
  );
}
