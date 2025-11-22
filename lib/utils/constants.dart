import 'package:flutter/material.dart';

/// 카테고리별 기본 색상 매핑
const Map<String, Color> categoryColors = {
  '업무': Color(0xFF80CBC4),
  '공부': Color(0xFF81D4FA),
  '개인': Color(0xFFFFAB91),
  '기타': Color(0xFFFFF59D),
};

/// 우선순위 (0: 낮음, 1: 보통, 2: 높음)
enum Priority { low, medium, high }

/// 카테고리 선택용 리스트
const List<String> categoryList = ['업무', '공부', '개인', '기타'];
