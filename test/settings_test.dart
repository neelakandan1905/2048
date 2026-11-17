import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/app.dart';
import 'package:game_2048/logic/settings_controller.dart';
import 'package:game_2048/models/settings.dart';
import 'package:game_2048/screens/settings_page.dart';
import 'package:game_2048/services/storage_service.dart';
import 'package:game_2048/theme/app_theme.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  // StorageService is a singleton that captures the store once, so share one.
  final store = InMemorySharedPreferencesAsync.empty();
  SharedPreferencesAsyncPlatform.instance = store;
  _platformTests();

  Future<SettingsController> pumpGame(WidgetTester tester, {required int score}) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS; // no ads in tests
    await store.clear(const ClearPreferencesParameters(filter: PreferencesFilters()), const SharedPreferencesOptions());
    await store.setString('game_state_v1', jsonEncode({
      'board': [[2, 0, 0, 0], [0, 8, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
      'score': score, 'bestScore': score, 'freeUndos': 1, 'status': 'playing',
      'wonAcknowledged': false, 'moves': score > 0 ? 5 : 0, 'history': [],
    }), const SharedPreferencesOptions());
    final settings = SettingsController();
    await settings.setSoundEnabled(false);
    await tester.binding.setSurfaceSize(const Size(390, 900));
    await tester.pumpWidget(Game2048App(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('changing difficulty mid-game asks first, then restarts', (tester) async {
    final settings = await pumpGame(tester, score: 40);

    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    expect(find.text('Switch to Hard?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(settings.difficulty, Difficulty.medium);

    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(settings.difficulty, Difficulty.hard);
    final saved = (await StorageService.instance.load())!;
    expect(saved.score, 0);
    expect(saved.freeUndos, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('before the first move, difficulty changes without asking', (tester) async {
    final settings = await pumpGame(tester, score: 0);
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Switch to'), findsNothing);
    expect(settings.difficulty, Difficulty.easy);
    expect((await StorageService.instance.load())!.freeUndos, 3);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('theme, tile colours and sound apply without a restart', (tester) async {
    final settings = await pumpGame(tester, score: 40);
    await tester.tap(find.text('Light'));
    await tester.tap(find.text('Ocean cool'));
    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Switch to'), findsNothing);
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.palette, TilePalette.ocean);
    expect(settings.soundEnabled, isTrue);
    expect((await StorageService.instance.load())!.score, 40);
    debugDefaultTargetPlatformOverride = null;
  });
}

/// Opens Settings from a bare app built for [platform] (no ads involved).
Future<(SettingsController, List<Difficulty>)> _openFor(WidgetTester tester, TargetPlatform platform) async {
  final settings = SettingsController();
  await settings.setSoundEnabled(false);
  final picked = <Difficulty>[];
  await tester.binding.setSurfaceSize(const Size(390, 900));
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light.copyWith(platform: platform),
    home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => openSettings(context, settings: settings, onDifficulty: (d) async => picked.add(d)),
      child: const Text('open'),
    ))),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return (settings, picked);
}

void _platformTests() {
  testWidgets('iPhone gets the iOS-style settings page', (tester) async {
    await _openFor(tester, TargetPlatform.iOS);
    expect(find.byType(CupertinoSettingsPage), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
  });

  testWidgets('Android gets Material settings with choice dialogs', (tester) async {
    final (settings, picked) = await _openFor(tester, TargetPlatform.android);
    expect(find.byType(MaterialSettingsPage), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);

    await tester.tap(find.text('Difficulty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    expect(picked, [Difficulty.hard]);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Tile colours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vibrant rainbow'));
    await tester.pumpAndSettle();
    expect(settings.palette, TilePalette.rainbow);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(settings.soundEnabled, isTrue);
  });
}
