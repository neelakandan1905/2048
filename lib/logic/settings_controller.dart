import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';

/// Player preferences, saved separately from the game in progress.
class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Difficulty _difficulty = Difficulty.medium;
  TilePalette _palette = TilePalette.sunset;
  bool _soundEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Difficulty get difficulty => _difficulty;
  TilePalette get palette => _palette;
  bool get soundEnabled => _soundEnabled;

  Future<void> load() async {
    final map = await StorageService.instance.loadSettings();
    if (map == null) return;
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    _themeMode = pick(ThemeMode.values, map['themeMode'], _themeMode);
    _difficulty = pick(Difficulty.values, map['difficulty'], _difficulty);
    _palette = pick(TilePalette.values, map['palette'], _palette);
    _soundEnabled = map['soundEnabled'] as bool? ?? _soundEnabled;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) => _update(() => _themeMode = value);
  Future<void> setPalette(TilePalette value) => _update(() => _palette = value);
  Future<void> setSoundEnabled(bool value) => _update(() => _soundEnabled = value);

  /// Use [GameController.changeDifficulty], which also restarts the game.
  Future<void> setDifficulty(Difficulty value) => _update(() => _difficulty = value);

  Future<void> _update(void Function() change) async {
    change();
    notifyListeners();
    await StorageService.instance.saveSettings({
      'themeMode': _themeMode.name,
      'difficulty': _difficulty.name,
      'palette': _palette.name,
      'soundEnabled': _soundEnabled,
    });
  }
}
