import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AdService.supported) await MobileAds.instance.initialize();
  await AdService.instance.initialize();
  runApp(const Game2048App());
}
