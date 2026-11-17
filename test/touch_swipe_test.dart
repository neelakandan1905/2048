import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/app.dart';
import 'package:game_2048/widgets/game_board.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

Future<Map<String, dynamic>> _saved() async => jsonDecode(
    (await SharedPreferencesAsyncPlatform.instance!.getString('game_state_v1', const SharedPreferencesOptions()))!) as Map<String, dynamic>;

void main() {
  // StorageService is a singleton that captures the store once, so share one.
  final store = InMemorySharedPreferencesAsync.empty();
  SharedPreferencesAsyncPlatform.instance = store;

  for (final (name, offset, row, col) in [
    ('down', const Offset(0, 150), 3, 1),
    ('up', const Offset(0, -150), 0, 1),
    ('left', const Offset(-150, 0), 1, 0),
    ('right', const Offset(150, 0), 1, 3),
  ]) {
    testWidgets('a touch swipe $name moves the tiles, not the page', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await store.setString('game_state_v1', jsonEncode({
        'board': [[0, 0, 0, 0], [0, 8, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
        'score': 0, 'bestScore': 0, 'freeUndos': 1, 'status': 'playing',
        'wonAcknowledged': false, 'soundEnabled': false, 'history': [],
      }), const SharedPreferencesOptions());
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(const Game2048App());
      await tester.pumpAndSettle();
      await tester.fling(find.byType(GameBoard), offset, 600); // touch by default
      await tester.pumpAndSettle();
      final board = (await _saved())['board'] as List;
      expect((board[row] as List)[col], 8, reason: 'board: $board');
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
