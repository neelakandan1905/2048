import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/game_controller.dart';
import '../logic/game_engine.dart';
import '../logic/settings_controller.dart';
import '../models/game_state.dart';
import '../models/settings.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/power_up_bar.dart';
import '../widgets/score_card.dart';
import 'settings_sheet.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings});
  final SettingsController settings;
  @override
  State<GameScreen> createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  @override
  void initState() {
    super.initState();
    _controller = GameController(settings: widget.settings);
    _controller.restore().then((_) => _showEndDialogIfNeeded());
  }

  /// A saved game can be restored in the won/lost state (app closed while the
  /// dialog was up), so show the matching dialog again instead of a frozen board.
  Future<void> _showEndDialogIfNeeded() async {
    if (!mounted) return;
    switch (_controller.state.status) {
      case GameStatus.won: await _showWonDialog();
      case GameStatus.lost: await _showLostDialog();
      case GameStatus.playing: break;
    }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _newGame() async {
    if (_controller.inProgress) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('Your current game progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New game')),
        ],
      ));
      if (confirmed != true) return;
    }
    await _controller.newGame();
  }

  void _openSettings() => showSettingsSheet(context, settings: widget.settings, onDifficulty: _changeDifficulty);

  /// Difficulty sets the rules of a game, so changing it starts a new one:
  /// straight away before the first move, otherwise after the player confirms.
  Future<void> _changeDifficulty(Difficulty difficulty) async {
    if (difficulty == widget.settings.difficulty) return;
    final inProgress = _controller.inProgress;
    if (inProgress) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text('Switch to ${difficulty.label}?'),
        content: const Text('Changing the difficulty restarts the game. Your current progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restart')),
        ],
      ));
      if (confirmed != true) return;
    }
    await _controller.changeDifficulty(difficulty);
    if (inProgress) _snack('New ${difficulty.label} game started.');
  }

  void _undo() {
    final s = _controller.state;
    if (s.history.isEmpty) return;
    if (s.freeUndos > 0) { _controller.undo(); return; }
    AdService.instance.showRewarded(
      onEarned: () => _controller.grantUndo(),
      onUnavailable: () => _snack('Rewarded ad is not ready. Please try again shortly.'),
    );
  }

  void _clearTwos() {
    if (!_controller.state.board.any((row) => row.contains(2))) {
      _snack('There are no 2 tiles to clear.');
      return;
    }
    AdService.instance.showRewarded(
      onEarned: () => _controller.clearTwos(),
      onUnavailable: () => _snack('Rewarded ad is not ready. Please try again shortly.'),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _handleMove(MoveDirection direction) async {
    final before = _controller.state;
    await _controller.move(direction);
    if (!mounted) return;
    final after = _controller.state;
    if (before.status != GameStatus.won && after.status == GameStatus.won) {
      await _showWonDialog();
    } else if (after.status == GameStatus.lost) {
      await _showLostDialog();
    }
  }

  Future<void> _showWonDialog() async {
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Text('2048 reached!'),
      content: const Text('Excellent work. Keep playing to chase a higher score.'),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Keep going'))],
    ));
    await _controller.acknowledgeWin(keepGoing: true);
  }

  Future<void> _showLostDialog() async {
    final score = _controller.state.score;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Text('No more moves'),
      content: Text('Final score: $score'),
      actions: [FilledButton(onPressed: () { Navigator.pop(context); _controller.newGame(); }, child: const Text('Play again'))],
    ));
  }

  static final _keyMoves = {
    LogicalKeyboardKey.arrowUp: MoveDirection.up, LogicalKeyboardKey.keyW: MoveDirection.up,
    LogicalKeyboardKey.arrowDown: MoveDirection.down, LogicalKeyboardKey.keyS: MoveDirection.down,
    LogicalKeyboardKey.arrowLeft: MoveDirection.left, LogicalKeyboardKey.keyA: MoveDirection.left,
    LogicalKeyboardKey.arrowRight: MoveDirection.right, LogicalKeyboardKey.keyD: MoveDirection.right,
  };

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final direction = _keyMoves[event.logicalKey];
    if (direction == null) return KeyEventResult.ignored;
    _handleMove(direction);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(autofocus: true, onKeyEvent: _onKey, child: AnimatedBuilder(
    animation: Listenable.merge([_controller, widget.settings]),
    builder: (context, _) {
      final state = _controller.state;
      final colors = GameColors.of(context);
      final iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: .7);
      return Scaffold(
        body: SafeArea(child: Column(children: [
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final boardSide = (constraints.maxWidth - 40).clamp(220.0, 480.0);
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      const Text('2048', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
                      const Spacer(),
                      IconButton(onPressed: _newGame, icon: Icon(Icons.refresh_rounded, color: iconColor), tooltip: 'New game'),
                      IconButton(onPressed: _openSettings, icon: Icon(Icons.settings_rounded, color: iconColor), tooltip: 'Settings'),
                    ]),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${widget.settings.difficulty.label} mode', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: ScoreCard(label: 'Score', value: state.score)),
                      const SizedBox(width: 10),
                      Expanded(child: ScoreCard(label: 'Best', value: state.bestScore)),
                    ]),
                    const SizedBox(height: 22),
                    Center(child: SizedBox(width: boardSide, child: GameBoard(state: state, onMove: _handleMove, palette: widget.settings.palette))),
                    const SizedBox(height: 18),
                    PowerUpBar(
                      freeUndos: state.freeUndos, canUndo: state.history.isNotEmpty,
                      onUndo: _undo, onClear: _clearTwos,
                    ),
                    const SizedBox(height: 12),
                    Text('Join the numbers. Reach 2048.', style: TextStyle(color: colors.muted, fontSize: 12)),
                  ]),
                ),
              ),
            );
          })),
          const BannerAdWidget(),
        ])),
      );
    },
  ));
}
