import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';
import '../models/todo_adapter_manual.dart';

/// Hive 기반 Todo 로컬 DB 단일톤 서비스.
///
/// - typeId 32의 [TodoAdapterManual]을 등록해서 과거 레코드도 안전하게 읽습니다.
/// - 'todos' 박스를 열고 Todo 목록을 읽고/쓰기 합니다.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  Box<Todo>? _box;
  bool _ready = false;

  /// Hive 및 'todos' 박스 초기화.
  ///
  /// 이미 초기화된 경우 두 번 실행해도 추가 작업은 하지 않습니다.
  Future<void> init() async {
    if (_ready) return;

    await Hive.initFlutter();

    // 수동 어댑터 등록: 과거 null 필드도 안전하게 읽음
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(TodoAdapterManual());
    }

    // 안전 오픈: 만약 구버전 포맷 문제로 열기 실패 시, 개발 모드에서는 박스 재생성
    try {
      _box = await Hive.openBox<Todo>('todos');
    } on TypeError catch (e) {
      // 개발 환경에서만 사용하는 것이 좋습니다.
      // 운영 데이터가 있다면 별도 마이그레이션 로직이 필요합니다.
      // ignore: avoid_print
      print(
        '[Hive] type error on open: $e → deleting box from disk and recreating (DEV ONLY)',
      );
      await Hive.deleteBoxFromDisk('todos');
      _box = await Hive.openBox<Todo>('todos');
    }

    _ready = true;
  }

  /// 외부에서 안전하게 호출할 수 있는 초기화 헬퍼.
  Future<void> ensureReady() async {
    if (!_ready) await init();
  }

  /// 전체 Todo 목록을 반환합니다.
  List<Todo> getTodos() {
    return _box?.values.toList(growable: false) ?? const [];
  }

  /// 새 Todo 추가
  Future<void> addTodo(Todo t) async {
    await ensureReady();
    await _box!.add(t);
  }

  /// index 위치의 Todo를 수정
  Future<void> updateTodoAt(int index, Todo t) async {
    await ensureReady();
    await _box!.putAt(index, t);
  }

  /// index 위치의 Todo를 삭제
  Future<void> deleteTodoAt(int index) async {
    await ensureReady();
    await _box!.deleteAt(index);
  }
}
