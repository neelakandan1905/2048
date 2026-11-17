import 'package:flutter/material.dart';
import 'logic/game_controller.dart';
import 'logic/settings_controller.dart';
import 'screens/game_screen.dart';
import 'screens/settings_page.dart';
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
  late final GameController _game;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? (SettingsController()..load());
    _game = GameController(settings: _settings);
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  // Named routes (not pushed widgets) so the web build keeps the browser
  // history in step: #/settings can be left with the back button or the iOS
  // back swipe. MaterialPageRoute slides in iOS-style, with swipe-back, on
  // Apple platforms.
  Route<void> _route(RouteSettings route) => MaterialPageRoute<void>(
        settings: route,
        builder: (context) => route.name == settingsRouteName
            ? SettingsPage(settings: _settings, controller: _game)
            : GameScreen(settings: _settings, controller: _game),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settings.themeMode,
          onGenerateRoute: _route,
        ),
      );
}
