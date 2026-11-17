import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key, required this.freeUndos, required this.canUndo, required this.onUndo, required this.onClear});
  final int freeUndos;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _ActionButton(icon: Icons.undo_rounded, label: 'Undo move', detail: freeUndos > 0 ? '$freeUndos free' : 'Watch ad', onTap: canUndo ? onUndo : null)),
    const SizedBox(width: 10),
    Expanded(child: _ActionButton(icon: Icons.auto_awesome_rounded, label: 'Clear 2s', detail: 'Reward', onTap: onClear)),
  ]);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.detail, required this.onTap});
  final IconData icon; final String label; final String detail; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Material(
    color: colors.card, borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12), onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        child: Row(children: [
          Icon(icon, color: onTap == null ? colors.muted.withValues(alpha: .5) : colors.accent, size: 21),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text(detail, style: TextStyle(color: colors.muted, fontSize: 10)),
          ])),
        ]),
      ),
    ),
  );
  }
}
