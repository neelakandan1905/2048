import 'dart:math';

enum MoveDirection { up, down, left, right }

class MoveResult {
  const MoveResult({required this.board, required this.scoreGained, required this.moved, required this.merged});
  final List<List<int>> board;
  final int scoreGained;
  final bool moved;
  final bool merged;
}

class GameEngine {
  static MoveResult move(List<List<int>> source, MoveDirection direction) {
    final board = source.map((row) => List<int>.from(row)).toList();
    var gained = 0;
    var merged = false;
    for (var i = 0; i < 4; i++) {
      final line = List<int>.generate(4, (j) {
        switch (direction) {
          case MoveDirection.left: return board[i][j];
          case MoveDirection.right: return board[i][3 - j];
          case MoveDirection.up: return board[j][i];
          case MoveDirection.down: return board[3 - j][i];
        }
      });
      final values = line.where((v) => v != 0).toList();
      final output = <int>[];
      for (var j = 0; j < values.length; j++) {
        if (j + 1 < values.length && values[j] == values[j + 1]) {
          final value = values[j] * 2;
          output.add(value);
          gained += value;
          merged = true;
          j++;
        } else {
          output.add(values[j]);
        }
      }
      while (output.length < 4) { output.add(0); }
      for (var j = 0; j < 4; j++) {
        final value = output[j];
        switch (direction) {
          case MoveDirection.left: board[i][j] = value; break;
          case MoveDirection.right: board[i][3 - j] = value; break;
          case MoveDirection.up: board[j][i] = value; break;
          case MoveDirection.down: board[3 - j][i] = value; break;
        }
      }
    }
    final moved = !_same(source, board);
    return MoveResult(board: board, scoreGained: gained, moved: moved, merged: merged);
  }

  static final _random = Random();

  /// Puts a 2 (or, with [fourChance], a 4) on a random empty cell.
  static void spawn(List<List<int>> board, {double fourChance = .1, Random? random}) {
    final rng = random ?? _random;
    final empty = <(int, int)>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) { if (board[r][c] == 0) empty.add((r, c)); }
    }
    if (empty.isEmpty) return;
    final (r, c) = empty[rng.nextInt(empty.length)];
    board[r][c] = rng.nextDouble() < fourChance ? 4 : 2;
  }

  static bool hasMoves(List<List<int>> board) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (board[r][c] == 0) return true;
        if (r < 3 && board[r][c] == board[r + 1][c]) return true;
        if (c < 3 && board[r][c] == board[r][c + 1]) return true;
      }
    }
    return false;
  }

  static bool contains2048(List<List<int>> board) =>
      board.any((row) => row.any((value) => value >= 2048));

  static bool _same(List<List<int>> a, List<List<int>> b) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }
}
