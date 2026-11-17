import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _stateKey = 'game_state_v1';
  static const _interstitialKey = 'last_interstitial_ms';

  Future<void> save(GameState state) async {
    final payload = {
      'board': state.board, 'score': state.score, 'bestScore': state.bestScore,
      'freeUndos': state.freeUndos, 'status': state.status.name,
      'wonAcknowledged': state.wonAcknowledged, 'soundEnabled': state.soundEnabled,
      'history': state.history.map((s) => {'board': s.board, 'score': s.score}).toList(),
    };
    await _prefs.setString(_stateKey, jsonEncode(payload));
  }

  Future<GameState?> load() async {
    final raw = await _prefs.getString(_stateKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final board = (map['board'] as List).map((r) => (r as List).map((v) => v as int).toList()).toList();
      if (board.length != 4 || board.any((r) => r.length != 4)) return null;
      final history = ((map['history'] as List?) ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return GameSnapshot(
          board: (m['board'] as List).map((r) => (r as List).map((v) => v as int).toList()).toList(),
          score: m['score'] as int,
        );
      }).toList();
      return GameState(
        board: board, score: map['score'] as int,
        bestScore: map['bestScore'] as int? ?? 0,
        freeUndos: map['freeUndos'] as int? ?? 1,
        status: GameStatus.values.firstWhere((s) => s.name == map['status'], orElse: () => GameStatus.playing),
        wonAcknowledged: map['wonAcknowledged'] as bool? ?? false,
        soundEnabled: map['soundEnabled'] as bool? ?? true,
        history: history,
      );
    } catch (_) { return null; }
  }

  Future<int> lastInterstitialMs() async => await _prefs.getInt(_interstitialKey) ?? 0;
  Future<void> setLastInterstitialMs(int value) => _prefs.setInt(_interstitialKey, value);
}
