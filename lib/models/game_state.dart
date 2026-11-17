import '../logic/game_engine.dart';
import 'settings.dart';

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
    required this.moves,
    required this.history,
  });

  final List<List<int>> board;
  final int score;
  final int bestScore;
  final int freeUndos;
  final GameStatus status;
  final bool wonAcknowledged;
  /// Moves made this game (hard mode drops an extra tile every few moves).
  final int moves;
  final List<GameSnapshot> history;

  factory GameState.initial({int bestScore = 0, Difficulty difficulty = Difficulty.medium}) {
    final board = List.generate(4, (_) => List<int>.filled(4, 0));
    GameEngine.spawn(board, fourChance: difficulty.fourChance);
    GameEngine.spawn(board, fourChance: difficulty.fourChance);
    return GameState(
      board: board, score: 0, bestScore: bestScore, freeUndos: difficulty.freeUndos,
      status: GameStatus.playing, wonAcknowledged: false,
      moves: 0, history: const [],
    );
  }

  GameState copyWith({
    List<List<int>>? board, int? score, int? bestScore, int? freeUndos,
    GameStatus? status, bool? wonAcknowledged, int? moves,
    List<GameSnapshot>? history,
  }) => GameState(
    board: board ?? this.board, score: score ?? this.score,
    bestScore: bestScore ?? this.bestScore,
    freeUndos: freeUndos ?? this.freeUndos,
    status: status ?? this.status,
    wonAcknowledged: wonAcknowledged ?? this.wonAcknowledged,
    moves: moves ?? this.moves,
    history: history ?? this.history,
  );
}
