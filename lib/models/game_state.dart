import 'dart:math';

enum GameStatus { playing, won, lost }

class GameSnapshot {
  const GameSnapshot({required this.board, required this.score});
  final List<List<int>> board;
  final int score;

  GameSnapshot copy() => GameSnapshot(
        board: board.map((row) => List<int>.from(row)).toList(),
        score: score,
      );
}

class GameState {
  const GameState({
    required this.board,
    required this.score,
    required this.bestScore,
    required this.freeUndos,
    required this.status,
    required this.wonAcknowledged,
    required this.soundEnabled,
    required this.history,
  });

  final List<List<int>> board;
  final int score;
  final int bestScore;
  final int freeUndos;
  final GameStatus status;
  final bool wonAcknowledged;
  final bool soundEnabled;
  final List<GameSnapshot> history;

  factory GameState.initial({int bestScore = 0}) {
    final board = List.generate(4, (_) => List<int>.filled(4, 0));
    _spawn(board);
    _spawn(board);
    return GameState(
      board: board, score: 0, bestScore: bestScore, freeUndos: 1,
      status: GameStatus.playing, wonAcknowledged: false,
      soundEnabled: true, history: const [],
    );
  }

  static void _spawn(List<List<int>> board) {
    final empty = <Point<int>>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (board[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[Random().nextInt(empty.length)];
    board[cell.x][cell.y] = Random().nextDouble() < .9 ? 2 : 4;
  }

  GameState copyWith({
    List<List<int>>? board, int? score, int? bestScore, int? freeUndos,
    GameStatus? status, bool? wonAcknowledged, bool? soundEnabled,
    List<GameSnapshot>? history,
  }) => GameState(
    board: board ?? this.board, score: score ?? this.score,
    bestScore: bestScore ?? this.bestScore,
    freeUndos: freeUndos ?? this.freeUndos,
    status: status ?? this.status,
    wonAcknowledged: wonAcknowledged ?? this.wonAcknowledged,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    history: history ?? this.history,
  );
}
