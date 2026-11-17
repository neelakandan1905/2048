import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_controller.dart';
import 'package:game_2048/logic/game_engine.dart';
import 'package:game_2048/logic/settings_controller.dart';
import 'package:game_2048/models/game_state.dart';
import 'package:game_2048/models/settings.dart';
import 'package:game_2048/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

GameState _state(List<List<int>> board, {List<GameSnapshot> history = const []}) =>
    GameState.initial().copyWith(board: board, history: history);

/// A controller with sound off (no audio plugin in tests).
Future<GameController> _controller({Difficulty difficulty = Difficulty.medium}) async {
  final settings = SettingsController();
  await settings.setSoundEnabled(false);
  await settings.setDifficulty(difficulty);
  return GameController(settings: settings);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('undo before reaching 2048 does not suppress the win', () async {
    final c = (await _controller())
      ..debugSetState(_state([
        [1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
      ], history: [GameSnapshot(board: List.generate(4, (_) => [0, 0, 0, 2]), score: 0)]));

    expect(await c.undo(), isTrue);
    expect(c.state.wonAcknowledged, isFalse);

    c.debugSetState(c.state.copyWith(board: [
      [1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
    ]));
    await c.move(MoveDirection.left);
    expect(c.state.status, GameStatus.won);
  });

  test('clearing a board of only 2s leaves a new tile', () async {
    final c = (await _controller())
      ..debugSetState(_state([
        [2, 0, 0, 0], [0, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 2],
      ]));
    await c.clearTwos();
    final tiles = c.state.board.expand((r) => r).where((v) => v != 0).toList();
    expect(tiles, hasLength(1));
    expect(tiles.single, anyOf(2, 4));
  });

  test('clearing 2s keeps other tiles and adds nothing', () async {
    final c = (await _controller())
      ..debugSetState(_state([
        [2, 8, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
      ]));
    await c.clearTwos();
    expect(c.state.board[0], [0, 8, 0, 0]);
    expect(c.state.board.expand((r) => r).where((v) => v != 0), hasLength(1));
  });

  test('a lost game is restored as lost', () async {
    final lost = [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 8]];
    final c = (await _controller())..debugSetState(_state(lost));
    await c.newGame(showAd: false); // persists a fresh game
    c.debugSetState(_state(lost).copyWith(status: GameStatus.lost));
    await StorageService.instance.save(c.state); // as if saved mid-game

    final restored = GameController();
    await restored.restore();
    expect(restored.state.status, GameStatus.lost);
  });

  group('difficulty', () {
    test('sets free undos per game', () async {
      expect((await _controller(difficulty: Difficulty.easy)).state.freeUndos, 3);
      expect((await _controller(difficulty: Difficulty.medium)).state.freeUndos, 1);
      expect((await _controller(difficulty: Difficulty.hard)).state.freeUndos, 0);
    });

    test('easy spawns 2s and 4s about equally', () {
      var fours = 0;
      for (var i = 0; i < 1000; i++) {
        final board = List.generate(4, (_) => List<int>.filled(4, 0));
        GameEngine.spawn(board, fourChance: Difficulty.easy.fourChance);
        final tile = board.expand((r) => r).firstWhere((v) => v != 0);
        expect(tile, anyOf(2, 4));
        if (tile == 4) fours++;
      }
      expect(fours, inInclusiveRange(400, 600));
    });

    test('hard drops two tiles on every 4th move', () async {
      final c = await _controller(difficulty: Difficulty.hard);
      final board = [[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]];
      int tiles() => c.state.board.expand((r) => r).where((v) => v != 0).length;

      c.debugSetState(_state(board).copyWith(moves: 2));
      await c.move(MoveDirection.right); // 3rd move: one new tile
      expect(tiles(), 2);

      c.debugSetState(_state(board).copyWith(moves: 3));
      await c.move(MoveDirection.right); // 4th move: two new tiles
      expect(tiles(), 3);
      expect(c.state.moves, 4);
    });

    test('changing difficulty saves it and starts a fresh game', () async {
      final c = await _controller();
      c.debugSetState(_state([[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]));
      await c.move(MoveDirection.left);
      expect(c.inProgress, isTrue);

      await c.changeDifficulty(Difficulty.easy);
      expect(c.inProgress, isFalse);
      expect(c.state.freeUndos, 3);

      final reloaded = SettingsController();
      await reloaded.load();
      expect(reloaded.difficulty, Difficulty.easy);
      expect(reloaded.soundEnabled, isFalse);
    });
  });
}
