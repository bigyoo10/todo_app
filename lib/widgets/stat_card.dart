import 'package:flutter/material.dart';

/// 간단한 지표(아이콘 + 값 + 라벨)를 보여주는 카드 위젯입니다.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.grey.shade300,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
