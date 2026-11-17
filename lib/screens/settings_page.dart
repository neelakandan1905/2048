import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/settings_controller.dart';
import '../models/settings.dart';
import '../theme/tile_colors.dart';
import '../widgets/adaptive_dialog.dart';

/// Route name of the settings page. On the web this becomes `#/settings`, a
/// real browser history entry, so back (button or iOS edge swipe) returns to
/// the game instead of leaving and reloading the page.
const settingsRouteName = '/settings';

/// Settings in the device's own style: an iOS Settings look on
/// iPhone/iPad/Mac, Material settings on Android and elsewhere. Appearance
/// and sound apply immediately; difficulty restarts the game (asking first
/// mid-game).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings, required this.controller});
  final SettingsController settings;
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          Future<void> onDifficulty(Difficulty d) => changeDifficulty(context, controller, d);
          return useCupertino(context)
              ? CupertinoSettingsPage(settings: settings, onDifficulty: onDifficulty)
              : MaterialSettingsPage(settings: settings, onDifficulty: onDifficulty);
        },
      );
}

/// Difficulty sets the rules of a game, so changing it starts a new one:
/// straight away before the first move, otherwise after the player confirms.
Future<void> changeDifficulty(BuildContext context, GameController controller, Difficulty difficulty) async {
  if (difficulty == controller.settings.difficulty) return;
  final inProgress = controller.inProgress;
  if (inProgress) {
    final confirmed = await showConfirmDialog(context,
        title: 'Switch to ${difficulty.label}?',
        message: 'Changing the difficulty restarts the game. Your current progress will be lost.',
        confirmLabel: 'Restart', destructive: true);
    if (!confirmed) return;
  }
  await controller.changeDifficulty(difficulty);
  if (inProgress && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('New ${difficulty.label} game started.'), behavior: SnackBarBehavior.floating));
  }
}

String _themeLabel(ThemeMode mode, {required bool cupertino}) => switch (mode) {
      ThemeMode.system => cupertino ? 'Automatic' : 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

class _Swatches extends StatelessWidget {
  const _Swatches(this.palette, {this.size = 18});
  final TilePalette palette;
  final double size;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (final c in TileColors.preview(palette))
          Container(
            width: size, height: size, margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(size / 4)),
          ),
      ]);
}

// ---------------------------------------------------------------- iOS ---

class CupertinoSettingsPage extends StatelessWidget {
  const CupertinoSettingsPage({super.key, required this.settings, required this.onDifficulty});
  final SettingsController settings;
  final Future<void> Function(Difficulty) onDifficulty;

  Widget _check(bool selected) => selected
      ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue, size: 20)
      : const SizedBox(width: 20);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: CustomScrollView(slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Settings'), previousPageTitle: '2048'),
          SliverSafeArea(
            top: false,
            sliver: SliverList.list(children: [
              CupertinoListSection.insetGrouped(
                header: const Text('DIFFICULTY'),
                footer: Text(settings.difficulty.description),
                children: [
                  for (final d in Difficulty.values)
                    CupertinoListTile(
                      title: Text(d.label),
                      trailing: _check(d == settings.difficulty),
                      onTap: () => onDifficulty(d),
                    ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('APPEARANCE'),
                footer: const Text('Automatic matches your device’s light or dark setting.'),
                children: [
                  for (final m in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
                    CupertinoListTile(
                      title: Text(_themeLabel(m, cupertino: true)),
                      trailing: _check(m == settings.themeMode),
                      onTap: () => settings.setThemeMode(m),
                    ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('TILE COLOURS'),
                children: [
                  for (final p in TilePalette.values)
                    CupertinoListTile(
                      title: Text(p.label),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        _Swatches(p),
                        const SizedBox(width: 10),
                        _check(p == settings.palette),
                      ]),
                      onTap: () => settings.setPalette(p),
                    ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                header: const Text('SOUND'),
                footer: const Text('Plays a sound when tiles move and merge.'),
                children: [
                  CupertinoListTile(
                    title: const Text('Sound'),
                    trailing: CupertinoSwitch(value: settings.soundEnabled, onChanged: settings.setSoundEnabled),
                    onTap: () => settings.setSoundEnabled(!settings.soundEnabled),
                  ),
                ],
              ),
            ]),
          ),
        ]),
      );
}

// ------------------------------------------------------------ Android ---

class MaterialSettingsPage extends StatelessWidget {
  const MaterialSettingsPage({super.key, required this.settings, required this.onDifficulty});
  final SettingsController settings;
  final Future<void> Function(Difficulty) onDifficulty;

  /// Android's list-preference pattern: a dialog of radio buttons that closes
  /// as soon as one is picked.
  Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required T current,
    required String Function(T) label,
    Widget Function(T)? trailing,
  }) =>
      showDialog<T>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
          content: RadioGroup<T>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final v in values)
                RadioListTile<T>(value: v, title: Text(label(v)), secondary: trailing?.call(v)),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(72, 24, 16, 8),
          child: Text(text, style: TextStyle(color: scheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        header('Game'),
        ListTile(
          leading: const Icon(Icons.speed_rounded),
          title: const Text('Difficulty'),
          subtitle: Text('${settings.difficulty.label} · ${settings.difficulty.description}'),
          onTap: () async {
            final d = await _choose(context, title: 'Difficulty', values: Difficulty.values,
                current: settings.difficulty, label: (d) => d.label);
            if (d != null) await onDifficulty(d);
          },
        ),
        header('Appearance'),
        ListTile(
          leading: const Icon(Icons.brightness_6_rounded),
          title: const Text('Theme'),
          subtitle: Text(_themeLabel(settings.themeMode, cupertino: false)),
          onTap: () async {
            final m = await _choose(context, title: 'Theme',
                values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                current: settings.themeMode, label: (m) => _themeLabel(m, cupertino: false));
            if (m != null) await settings.setThemeMode(m);
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Tile colours'),
          subtitle: Text(settings.palette.label),
          trailing: _Swatches(settings.palette, size: 16),
          onTap: () async {
            final p = await _choose(context, title: 'Tile colours', values: TilePalette.values,
                current: settings.palette, label: (p) => p.label, trailing: (p) => _Swatches(p, size: 14));
            if (p != null) await settings.setPalette(p);
          },
        ),
        header('Sound'),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: const Text('Sound'),
          subtitle: const Text('Play a sound when tiles move and merge'),
          value: settings.soundEnabled,
          onChanged: settings.setSoundEnabled,
        ),
      ]),
    );
  }
}
