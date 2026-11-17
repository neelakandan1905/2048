import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  /// google_mobile_ads only runs on Android and iOS. On web/desktop (local
  /// testing) ads are skipped.
  static bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  // TODO: Replace with production Ad Unit ID.
  static const bannerId = 'ca-app-pub-3940256099942544/6300978111';
  // TODO: Replace with production Ad Unit ID.
  static const interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  // TODO: Replace with production Ad Unit ID.
  static const rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static const _freeRewards = bool.fromEnvironment('FREE_REWARDS');

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !supported) return;
    _initialized = true;
    loadInterstitial();
    loadRewarded();
  }

  BannerAd createBanner({required VoidCallback onLoaded, required VoidCallback onFailed}) {
    return BannerAd(
      adUnitId: bannerId, size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) { ad.dispose(); onFailed(); },
      ),
    )..load();
  }

  void loadInterstitial() {
    if (_interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialId, request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  Future<void> showInterstitialIfAllowed() async {
    if (!supported) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = await StorageService.instance.lastInterstitialMs();
    if (now - last < const Duration(minutes: 3).inMilliseconds) return;
    final ad = _interstitial;
    if (ad == null) { loadInterstitial(); return; }
    _interstitial = null;
    await StorageService.instance.setLastInterstitialMs(now);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); loadInterstitial(); },
      onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); loadInterstitial(); },
    );
    await ad.show();
  }

  void loadRewarded() {
    if (_rewarded != null) return;
    RewardedAd.load(
      adUnitId: rewardedId, request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void showRewarded({required VoidCallback onEarned, required VoidCallback onUnavailable}) {
    if (!supported) {
      // No ads on web/desktop: grant the reward in debug builds, or in test
      // builds made with --dart-define=FREE_REWARDS=true, so power-ups can be tested.
      (kDebugMode || _freeRewards) ? onEarned() : onUnavailable();
      return;
    }
    final ad = _rewarded;
    if (ad == null) { onUnavailable(); loadRewarded(); return; }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); loadRewarded(); },
      onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); loadRewarded(); },
    );
    ad.show(onUserEarnedReward: (_, __) {
      onEarned();
    });
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}
