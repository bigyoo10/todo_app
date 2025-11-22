import 'package:hive/hive.dart';

part 'todo.g.dart';

/// 단일 Todo 아이템 모델 (Hive에 저장되는 엔티티).
@HiveType(typeId: 32)
class Todo extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String? category;

  /// 0/1/2 (낮음/보통/높음)
  @HiveField(4)
  int? priority;

  /// 예약 알림 시각 (null이면 알림 없음)
  @HiveField(5)
  DateTime? notificationTime;

  /// 완료 여부
  @HiveField(6)
  bool isCompleted;

  /// 완료된 시각 (완료 해제 시 null)
  @HiveField(7)
  DateTime? completedAt;

  /// 알림 예약에 사용하는 고유 ID
  @HiveField(8)
  int? notificationId;

  /// 리스트 정렬 순서 (drag & drop 재정렬에 사용)
  @HiveField(9)
  int? sortOrder;

  Todo({
    required this.title,
    required this.description,
    required this.createdAt,
    this.category,
    this.priority,
    this.notificationTime,
    this.isCompleted = false,
    this.completedAt,
    this.notificationId,
    this.sortOrder,
  });

  /// 부분 변경을 위한 copyWith 패턴
  Todo copyWith({
    String? title,
    String? description,
    DateTime? createdAt,
    String? category,
    int? priority,
    DateTime? notificationTime,
    bool? isCompleted,
    DateTime? completedAt,
    int? notificationId,
    int? sortOrder,
  }) {
    return Todo(
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      notificationTime: notificationTime ?? this.notificationTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notificationId: notificationId ?? this.notificationId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
