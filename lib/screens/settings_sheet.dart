import 'package:flutter/material.dart';
import '../logic/settings_controller.dart';
import '../models/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tile_colors.dart';

/// Settings as a bottom sheet. Appearance and sound apply immediately;
/// difficulty goes through [onDifficulty], which restarts the game (after
/// asking, if a game is in progress).
Future<void> showSettingsSheet(
  BuildContext context, {
  required SettingsController settings,
  required Future<void> Function(Difficulty) onDifficulty,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => _SettingsBody(settings: settings, onDifficulty: onDifficulty),
      ),
    );

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.settings, required this.onDifficulty});
  final SettingsController settings;
  final Future<void> Function(Difficulty) onDifficulty;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const _Heading('Difficulty'),
          SegmentedButton<Difficulty>(
            showSelectedIcon: false,
            segments: [for (final d in Difficulty.values) ButtonSegment(value: d, label: Text(d.label))],
            selected: {settings.difficulty},
            onSelectionChanged: (s) => onDifficulty(s.first),
          ),
          const SizedBox(height: 6),
          Text(settings.difficulty.description, style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 20),
          const _Heading('Theme'),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_iphone_rounded), label: Text('Device')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: 20),
          const _Heading('Tile colours'),
          for (final p in TilePalette.values)
            _PaletteOption(palette: p, selected: p == settings.palette, onTap: () => settings.setPalette(p)),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Play a sound when tiles move and merge', style: TextStyle(color: colors.muted, fontSize: 12)),
            value: settings.soundEnabled,
            onChanged: settings.setSoundEnabled,
          ),
        ]),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(color: GameColors.of(context).muted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      );
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({required this.palette, required this.selected, required this.onTap});
  final TilePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? colors.accent : colors.emptyCell, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Expanded(child: Text(palette.label, style: const TextStyle(fontWeight: FontWeight.w700))),
              for (final c in TileColors.preview(palette))
                Container(
                  width: 22, height: 22, margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
                ),
              const SizedBox(width: 10),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? colors.accent : colors.muted, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}
