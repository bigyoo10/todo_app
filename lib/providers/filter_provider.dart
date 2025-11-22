import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';

/// (현재 미사용) 리스트 필터/정렬 상태를 표현하는 Provider.
/// 향후 카테고리/우선순위/정렬 기능을 추가할 때 사용할 수 있습니다.
final filterProvider = StateProvider<FilterState>((ref) => FilterState());

/// 화면에 적용할 필터 조건 값들.
class FilterState {
  String? category;
  Priority? priority;
  bool? isCompleted;
  SortType sortType = SortType.creationDate;
}

/// 정렬 기준.
enum SortType { creationDate, priority, title }
