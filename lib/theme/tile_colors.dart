import 'package:flutter/material.dart';

class TileColors {
  static Color forValue(int value) => switch (value) {
    0 => const Color(0xFF252529),
    2 => const Color(0xFF303A38),
    4 => const Color(0xFF455C55),
    8 => const Color(0xFF667F69),
    16 => const Color(0xFF879B68),
    32 => const Color(0xFFA1A66B),
    64 => const Color(0xFFD4A65D),
    128 => const Color(0xFFE6B96C),
    256 => const Color(0xFFCF9868),
    512 => const Color(0xFFC87979),
    1024 => const Color(0xFFB66D9C),
    2048 => const Color(0xFF9A7BD1),
    _ => const Color(0xFF6D8FE8),
  };
}
