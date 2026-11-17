import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyRules on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };

  /// Chance that a new tile is a 4 instead of a 2.
  double get fourChance => this == Difficulty.easy ? .5 : .1;

  /// Undos available without watching an ad, per game.
  int get freeUndos => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 1,
        Difficulty.hard => 0,
      };

  /// On hard, every Nth move drops two new tiles instead of one.
  int? get extraTileEvery => this == Difficulty.hard ? 4 : null;

  String get description => switch (this) {
        Difficulty.easy => 'New tiles are 2 or 4 at random. 3 free undos.',
        Difficulty.medium => 'Classic: new tiles are mostly 2s. 1 free undo.',
        Difficulty.hard => 'Every 4th move drops 2 new tiles. No free undos.',
      };
}

enum TilePalette { sunset, ocean, rainbow }

extension TilePaletteLabel on TilePalette {
  String get label => switch (this) {
        TilePalette.sunset => 'Warm sunset',
        TilePalette.ocean => 'Ocean cool',
        TilePalette.rainbow => 'Vibrant rainbow',
      };
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => 'Device',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}
