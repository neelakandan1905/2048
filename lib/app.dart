import 'package:flutter/material.dart';
import 'logic/settings_controller.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

class Game2048App extends StatefulWidget {
  /// [settings] should already be loaded (see main.dart) so the first frame
  /// uses the saved theme; without it the app loads them itself.
  const Game2048App({super.key, this.settings});
  final SettingsController? settings;

  @override
  State<Game2048App> createState() => _Game2048AppState();
}

class _Game2048AppState extends State<Game2048App> {
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? (SettingsController()..load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settings.themeMode,
          home: GameScreen(settings: _settings),
        ),
      );
}
