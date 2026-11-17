import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/app.dart';
import 'package:game_2048/logic/settings_controller.dart';
import 'package:game_2048/models/settings.dart';
import 'package:game_2048/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  // StorageService is a singleton that captures the store once, so share one.
  final store = InMemorySharedPreferencesAsync.empty();
  SharedPreferencesAsyncPlatform.instance = store;

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
