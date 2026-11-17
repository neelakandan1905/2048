import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../logic/game_engine.dart';
import 'game_tile.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key, required this.state, required this.onMove});
  final GameState state;
  final ValueChanged<MoveDirection> onMove;
  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Offset _start = Offset.zero;
  void _end(DragEndDetails details) {
    final delta = details.localPosition - _start;
    final velocity = details.velocity.pixelsPerSecond;
    final dx = delta.dx.abs();
    final dy = delta.dy.abs();
    final vx = velocity.dx.abs();
    final vy = velocity.dy.abs();
    final horizontal = dx > dy || (dx == dy && vx >= vy);
    final distance = horizontal ? dx : dy;
    final speed = horizontal ? vx : vy;
    if (distance < 22 && speed < 180) return;
    if (horizontal) {
      widget.onMove((delta.dx >= 0 || (delta.dx == 0 && velocity.dx > 0)) ? MoveDirection.right : MoveDirection.left);
    } else {
      widget.onMove((delta.dy >= 0 || (delta.dy == 0 && velocity.dy > 0)) ? MoveDirection.down : MoveDirection.up);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final side = constraints.maxWidth;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _start = d.localPosition,
      onPanEnd: _end,
      child: Container(
        width: side, height: side, padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1D), borderRadius: BorderRadius.circular(14)),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 16,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 7, mainAxisSpacing: 7),
          itemBuilder: (context, index) => GameTile(
            key: ValueKey('cell_$index'),
            value: widget.state.board[index ~/ 4][index % 4],
          ),
        ),
      ),
    );
  });
}
