import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'logic/settings_controller.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AdService.supported) await MobileAds.instance.initialize();
  await AdService.instance.initialize();
  final settings = SettingsController();
  await settings.load();
  runApp(Game2048App(settings: settings));
}
