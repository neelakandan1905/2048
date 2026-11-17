import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/app.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('a game saved as lost shows the game-over dialog on launch', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS; // no ads in tests
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      'game_state_v1': jsonEncode({
        'board': [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 8]],
        'score': 1234, 'bestScore': 1234, 'freeUndos': 1, 'status': 'lost',
        'wonAcknowledged': false, 'soundEnabled': false, 'history': [],
      }),
    });
    await tester.pumpWidget(const Game2048App());
    await tester.pumpAndSettle();
    expect(find.text('No more moves'), findsOneWidget);
    expect(find.text('Final score: 1234'), findsOneWidget);

    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('No more moves'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
