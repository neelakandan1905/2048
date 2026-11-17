import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_controller.dart';
import 'package:game_2048/logic/game_engine.dart';
import 'package:game_2048/models/game_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

GameState _state(List<List<int>> board, {List<GameSnapshot> history = const []}) =>
    GameState.initial().copyWith(board: board, history: history, soundEnabled: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('undo before reaching 2048 does not suppress the win', () async {
    final c = GameController()
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
    final c = GameController()
      ..debugSetState(_state([
        [2, 0, 0, 0], [0, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 2],
      ]));
    await c.clearTwos();
    final tiles = c.state.board.expand((r) => r).where((v) => v != 0).toList();
    expect(tiles, hasLength(1));
    expect(tiles.single, anyOf(2, 4));
  });

  test('clearing 2s keeps other tiles and adds nothing', () async {
    final c = GameController()
      ..debugSetState(_state([
        [2, 8, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
      ]));
    await c.clearTwos();
    expect(c.state.board[0], [0, 8, 0, 0]);
    expect(c.state.board.expand((r) => r).where((v) => v != 0), hasLength(1));
  });

  test('a lost game is restored as lost', () async {
    final lost = [[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 8]];
    final c = GameController()..debugSetState(_state(lost));
    await c.newGame(showAd: false); // persists a fresh game
    c.debugSetState(_state(lost).copyWith(status: GameStatus.lost));
    await c.toggleSound(); // persists the lost state

    final restored = GameController();
    await restored.restore();
    expect(restored.state.status, GameStatus.lost);
  });
}
