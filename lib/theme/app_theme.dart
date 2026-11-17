import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Surface colours of the game UI that aren't covered by Material's scheme.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.board,
    required this.emptyCell,
    required this.card,
    required this.muted,
    required this.accent,
  });

  final Color board;
  final Color emptyCell;
  final Color card;
  final Color muted;
  final Color accent;

  static GameColors of(BuildContext context) => Theme.of(context).extension<GameColors>()!;

  static const dark = GameColors(
    board: Color(0xFF1A1A1D),
    emptyCell: Color(0xFF252529),
    card: Color(0xFF121212),
    muted: Color(0xFF858585),
    accent: Color(0xFFA1A66B),
  );

  static const light = GameColors(
    board: Color(0xFFD9D2C8),
    emptyCell: Color(0xFFE9E3DA),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFF7A736A),
    accent: Color(0xFF6E7340),
  );

  @override
  GameColors copyWith({Color? board, Color? emptyCell, Color? card, Color? muted, Color? accent}) => GameColors(
        board: board ?? this.board,
        emptyCell: emptyCell ?? this.emptyCell,
        card: card ?? this.card,
        muted: muted ?? this.muted,
        accent: accent ?? this.accent,
      );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    return GameColors(
      board: Color.lerp(board, other.board, t)!,
      emptyCell: Color.lerp(emptyCell, other.emptyCell, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: Colors.black,
    foreground: Colors.white,
    dialog: const Color(0xFF181818),
    colors: GameColors.dark,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: const Color(0xFFF7F4EF),
    foreground: const Color(0xFF1F1C19),
    dialog: Colors.white,
    colors: GameColors.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color dialog,
    required GameColors colors,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ).copyWith(primary: colors.accent, surface: background, onSurface: foreground);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(backgroundColor: background, elevation: 0),
      dialogTheme: DialogThemeData(backgroundColor: dialog),
      // iOS-style screens and alerts use the system blue, like native apps.
      cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness, primaryColor: CupertinoColors.systemBlue),
      extensions: [colors],
    );
  }
}
