import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_engine.dart';

void main() {
  test('left move merges equal adjacent tiles once', () {
    final board = [
      [2, 2, 2, 2], [0, 0, 0, 0], [4, 4, 8, 0], [0, 0, 0, 0],
    ];
    final result = GameEngine.move(board, MoveDirection.left);
    expect(result.board[0], [4, 4, 0, 0]);
    expect(result.board[2], [8, 8, 0, 0]);
    expect(result.scoreGained, 16); // 4+4 from row 0, 8 from row 2
    expect(result.merged, isTrue);
  });

  test('right move compacts toward right edge', () {
    final result = GameEngine.move([
      [2, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0],
    ], MoveDirection.right);
    expect(result.board[0], [0, 0, 0, 4]);
  });

  test('unchanged move is invalid', () {
    final result = GameEngine.move([
      [2, 4, 8, 16], [4, 8, 16, 32], [8, 16, 32, 64], [16, 32, 64, 128],
    ], MoveDirection.left);
    expect(result.moved, isFalse);
  });

  test('game over detection requires no empties or equal neighbours', () {
    final board = [
      [2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 2],
    ];
    expect(GameEngine.hasMoves(board), isFalse);
    board[3][3] = 0;
    expect(GameEngine.hasMoves(board), isTrue);
  });
}
