import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF858585), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    ]),
  );
}
