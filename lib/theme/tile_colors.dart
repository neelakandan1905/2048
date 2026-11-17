import 'package:flutter/material.dart';
import '../models/settings.dart';

/// Tile colours for each palette, from 2 up to 2048, plus one for anything
/// bigger. Empty cells use the theme's [GameColors.emptyCell].
class TileColors {
  static const _palettes = {
    TilePalette.sunset: [
      Color(0xFFFFF1DC), Color(0xFFFFE0B2), Color(0xFFFFC27A), Color(0xFFFFA45C),
      Color(0xFFFF8552), Color(0xFFF2624B), Color(0xFFF4B942), Color(0xFFEFA530),
      Color(0xFFE8577E), Color(0xFFC9418F), Color(0xFF8E44AD), Color(0xFF5B2C83),
    ],
    TilePalette.ocean: [
      Color(0xFFE3F4F4), Color(0xFFC5ECEA), Color(0xFF8FD9D3), Color(0xFF5CC4C8),
      Color(0xFF3AA8C9), Color(0xFF2E86C1), Color(0xFF2C6AB0), Color(0xFF3F51B5),
      Color(0xFF6247AA), Color(0xFF7B3F98), Color(0xFFF2B705), Color(0xFF1B2A49),
    ],
    TilePalette.rainbow: [
      Color(0xFFD9D9DE), Color(0xFFB8BCC8), Color(0xFFEF5350), Color(0xFFFF8A3D),
      Color(0xFFF7C531), Color(0xFFA5D63F), Color(0xFF43B866), Color(0xFF1FA99A),
      Color(0xFF2F80ED), Color(0xFF5B5BD6), Color(0xFF9B51E0), Color(0xFF333333),
    ],
  };

  /// Background of a non-empty tile.
  static Color forValue(TilePalette palette, int value) {
    final colors = _palettes[palette]!;
    var index = 0;
    for (var v = value; v > 2 && index < colors.length - 1; v ~/= 2) { index++; }
    return colors[index];
  }

  /// Dark text on light tiles, white on dark ones.
  static Color textOn(Color background) =>
      background.computeLuminance() > .45 ? const Color(0xFF3B3530) : Colors.white;

  /// A few sample colours, for the palette picker.
  static List<Color> preview(TilePalette palette) {
    final colors = _palettes[palette]!;
    return [colors[0], colors[2], colors[4], colors[6], colors[10]];
  }
}
