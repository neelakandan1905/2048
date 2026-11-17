import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(color: colors.muted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    ]),
  );
  }
}
