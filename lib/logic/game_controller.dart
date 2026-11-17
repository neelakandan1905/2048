import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import 'game_engine.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';

class GameController extends ChangeNotifier {
  GameController() : _state = GameState.initial();
  GameState _state;
  GameState get state => _state;
  bool _ready = false;

  Future<void> restore() async {
    final saved = await StorageService.instance.load();
    if (saved != null) _state = saved;
    _ready = true;
    notifyListeners();
    if (saved == null) await _persist();
  }

  Future<void> move(MoveDirection direction) async {
    if (!_ready || _state.status == GameStatus.lost) return;
    final result = GameEngine.move(_state.board, direction);
    if (!result.moved) return;
    final history = [..._state.history, GameSnapshot(board: _copy(_state.board), score: _state.score)];
    if (history.length > 5) history.removeAt(0);
    final board = _copy(result.board);
    _spawn(board);
    final score = _state.score + result.scoreGained;
    final won = !_state.wonAcknowledged && GameEngine.contains2048(board);
    final lost = !GameEngine.hasMoves(board);
    _state = _state.copyWith(
      board: board, score: score, bestScore: max(_state.bestScore, score),
      history: history, status: lost ? GameStatus.lost : (won ? GameStatus.won : GameStatus.playing),
    );
    // Sound plays before the first await so that, on the web, it stays inside
    // the touch/key event (phone browsers require that).
    if (_state.soundEnabled) {
      result.merged ? SoundService.instance.merge() : SoundService.instance.move();
    }
    await _persist();
    notifyListeners();
    if (lost) AdService.instance.showInterstitialIfAllowed();
  }

  Future<void> acknowledgeWin({required bool keepGoing}) async {
    _state = _state.copyWith(wonAcknowledged: true, status: GameStatus.playing);
    await _persist();
    notifyListeners();
  }

  Future<void> newGame({bool showAd = true}) async {
    final best = _state.bestScore;
    _state = GameState.initial(bestScore: best).copyWith(soundEnabled: _state.soundEnabled);
    await _persist();
    notifyListeners();
    if (showAd) AdService.instance.showInterstitialIfAllowed();
  }

  Future<bool> undo() async {
    if (_state.history.isEmpty) return false;
    if (_state.freeUndos <= 0) return false;
    final history = [..._state.history];
    final previous = history.removeLast();
    _state = _state.copyWith(
      board: _copy(previous.board), score: previous.score,
      history: history, freeUndos: _state.freeUndos - 1,
      status: GameStatus.playing,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> grantUndo() async {
    if (_state.history.isEmpty) return;
    final history = [..._state.history];
    final previous = history.removeLast();
    _state = _state.copyWith(board: _copy(previous.board), score: previous.score,
      history: history, status: GameStatus.playing);
    await _persist();
    notifyListeners();
  }

  Future<void> clearTwos() async {
    final board = _copy(_state.board);
    var changed = false;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (board[r][c] == 2) { board[r][c] = 0; changed = true; }
      }
    }
    if (!changed) return;
    // A board of only 2s would be left empty and unplayable: give it a tile.
    if (board.every((row) => row.every((v) => v == 0))) _spawn(board);
    _state = _state.copyWith(board: board, status: GameStatus.playing);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _state = _state.copyWith(soundEnabled: !_state.soundEnabled);
    await _persist();
    notifyListeners();
  }

  @visibleForTesting
  void debugSetState(GameState state) { _state = state; _ready = true; }

  Future<void> _persist() => StorageService.instance.save(_state);
  static List<List<int>> _copy(List<List<int>> board) => board.map((r) => List<int>.from(r)).toList();
  static void _spawn(List<List<int>> board) {
    final empty = <Point<int>>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) { if (board[r][c] == 0) empty.add(Point(r, c)); }
    }
    if (empty.isEmpty) return;
    final p = empty[Random().nextInt(empty.length)];
    board[p.x][p.y] = Random().nextDouble() < .9 ? 2 : 4;
  }
}
