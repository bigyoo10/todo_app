import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 카테고리/우선순위에 따라 배경색이 달라지는 Chip 위젯입니다.
class CategoryChip extends StatelessWidget {
  final String label;
  final int? priority;

  const CategoryChip({super.key, required this.label, this.priority});

  @override
  Widget build(BuildContext context) {
    Color bgColor = categoryColors[label] ?? Colors.grey.shade200;

    if (priority != null) {
      bgColor = [Colors.green, Colors.orange, Colors.red][priority!];
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: bgColor,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }
}
