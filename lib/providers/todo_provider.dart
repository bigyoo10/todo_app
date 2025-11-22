import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';
/// Todo 목록 전역 상태 (Hive + 로컬 알림 연동)
final todoListProvider =
StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier();
});
/// Todo 목록을 관리하는 StateNotifier.
/// - Hive(LocalDbService)와 동기화
/// - 알림(NotificationService) 예약/취소를 함께 처리합니다.
class TodoListNotifier extends StateNotifier<List<Todo>> {
  TodoListNotifier() : super([]) {
    _init();
  }
  Future<void> _init() async {
    await LocalDbService.instance.init();
    var items = LocalDbService.instance.getTodos();
// 1회 마이그레이션: 누락된 notificationId/sortOrder 채워 넣기
    for (int i = 0; i < items.length; i++) {
      final t = items[i];
      int? nid = t.notificationId;
      int? order = t.sortOrder; // nullable
      if (nid == null) {
        nid = (t.createdAt.millisecondsSinceEpoch & 0x7fffffff) ^ i;
      }
      if (order == null) {
        order = i; // 기존 순서를 기준으로 기본값 부여
      }
      if (nid != t.notificationId || order != t.sortOrder) {
        final fixed = t.copyWith(notificationId: nid, sortOrder: order);
        items[i] = fixed;
        await LocalDbService.instance.updateTodoAt(i, fixed);
      }
    }
    items.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    state = items;
  }
  int _newNotificationId() =>
      DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  int _indexOfTodo(Todo t) {
    if (t.notificationId != null) {
      final i = state.indexWhere((e) => e.notificationId == t.notificationId);
      if (i != -1) return i;
    }
    var i = state.indexWhere((e) => identical(e, t));
    if (i != -1) return i;
    i = state.indexWhere((e) => e.title == t.title && e.createdAt == t.createdAt);
    return i;
  }
  int _coerceIndex(dynamic target) {
    if (target is int) return target;
    if (target is Todo) return _indexOfTodo(target);
    return -1;
  }
  Future<void> addTodo(Todo t) async {
    await LocalDbService.instance.ensureReady();
    final withId = t.notificationId == null
        ? t.copyWith(notificationId: _newNotificationId())
        : t;
    final nextOrder = state.isEmpty ? 0 : state.length;
    final toSave = withId.copyWith(sortOrder: nextOrder);
    await LocalDbService.instance.addTodo(toSave);
    state = LocalDbService.instance.getTodos()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (toSave.notificationTime != null && !toSave.isCompleted && toSave.notificationId != null) {
      await NotificationService.instance.scheduleNotification(
        toSave.notificationId!,
        toSave.title,
        toSave.notificationTime!,
      );
    }
  }
  Future<void> updateTodoAt(int index, Todo updated) async {
    await LocalDbService.instance.ensureReady();
    final current = state[index];
    final merged = updated.copyWith(
      notificationId: updated.notificationId ?? current.notificationId ?? _newNotificationId(),
      sortOrder: updated.sortOrder ?? current.sortOrder ?? index,
    );
    await LocalDbService.instance.updateTodoAt(index, merged);
    state = LocalDbService.instance.getTodos()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (merged.notificationTime == null || merged.isCompleted) {
      if (merged.notificationId != null) {
        await NotificationService.instance.cancelNotification(merged.notificationId!);
      }
    } else {
      if (merged.notificationId != null) {
        await NotificationService.instance.scheduleNotification(
          merged.notificationId!,
          merged.title,
          merged.notificationTime!,
        );
      }
    }
  }
// 다양한 UI 호출을 모두 수용하는 updateTodo
  Future<void> updateTodo(dynamic target, [Todo? data]) async {
    int index = -1;
    late Todo updated;
    if (target is int && data != null) {
      index = target;
      updated = data;
    } else if (target is Todo && data == null) {
      index = _coerceIndex(target);
      updated = target;
    } else if (target is Todo && data is Todo) {
      index = _coerceIndex(target);
      updated = data;
    } else {
      return;
    }
    if (index < 0 || index >= state.length) return;
    await updateTodoAt(index, updated);
  }
  Future<void> deleteTodo(dynamic target) async {
    final i = _coerceIndex(target);
    if (i < 0 || i >= state.length) return;
    await deleteTodoAt(i);
  }
  Future<void> deleteTodoAt(int index) async {
    await LocalDbService.instance.ensureReady();
    final todo = state[index];
    if (todo.notificationId != null) {
      await NotificationService.instance.cancelNotification(todo.notificationId!);
    }
    await LocalDbService.instance.deleteTodoAt(index);
    state = LocalDbService.instance.getTodos()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }
  Future<void> toggleComplete(dynamic target) async {
    final i = _coerceIndex(target);
    if (i < 0 || i >= state.length) return;
    final t = state[i];
    final toggled = t.copyWith(
      isCompleted: !t.isCompleted,
      completedAt: t.isCompleted ? null : DateTime.now(),
    );
    await LocalDbService.instance.updateTodoAt(i, toggled);
    state = LocalDbService.instance.getTodos()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (toggled.isCompleted) {
      if (toggled.notificationId != null) {
        await NotificationService.instance.cancelNotification(toggled.notificationId!);
      }
    } else {
      if (toggled.notificationTime != null && toggled.notificationId != null) {
        await NotificationService.instance.scheduleNotification(
          toggled.notificationId!,
          toggled.title,
          toggled.notificationTime!,
        );
      }
    }
  }
  /// 드래그 정렬: 메모리 순서 변경 + sortOrder 재부여 + DB 동기화
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<Todo>.from(state);
    final item = list.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(sortOrder: i);
      await LocalDbService.instance.updateTodoAt(i, list[i]);
    }
    state = List<Todo>.from(list)
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }
}
