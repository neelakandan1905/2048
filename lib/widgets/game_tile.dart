import 'package:flutter/material.dart';
import '../theme/tile_colors.dart';

class GameTile extends StatelessWidget {
  const GameTile({super.key, required this.value});
  final int value;
  @override
  Widget build(BuildContext context) {
    final digits = value.toString().length;
    final size = digits <= 2 ? 27.0 : digits == 3 ? 23.0 : digits == 4 ? 19.0 : 16.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(color: TileColors.forValue(value), borderRadius: BorderRadius.circular(9)),
      child: Center(
        child: AnimatedScale(
          scale: value == 0 ? .92 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: value == 0 ? const SizedBox.shrink(key: ValueKey('empty')) : Text(
              '$value', key: ValueKey(value),
              maxLines: 1, softWrap: false,
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -.8),
            ),
          ),
        ),
      ),
    );
  }
}
