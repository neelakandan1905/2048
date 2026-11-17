import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '2048',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const GameScreen(),
      );
}
