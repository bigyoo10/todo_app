import 'package:hive_flutter/hive_flutter.dart';

/// 간단한 key-value 설정 저장용 Hive 래퍼.
///
/// bool/int 정도만 사용하므로, 각 타입별 헬퍼 메서드를 제공하는 방식으로 구현했습니다.
class PrefsService {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  Box? _box;
  bool _ready = false;

  /// 'prefs' 박스 초기화.
  ///
  /// Hive.initFlutter()는 [LocalDbService] 쪽에서 한 번 호출된다고 가정합니다.
  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox('prefs');
    _ready = true;
  }

  Future<void> ensureReady() async {
    if (!_ready) await init();
  }

  // ---- Bool ----
  Future<void> setBool(String key, bool value) async {
    await ensureReady();
    await _box!.put(key, value);
  }

  Future<bool?> getBool(String key) async {
    await ensureReady();
    final v = _box!.get(key);
    if (v is bool) return v;
    return null;
  }

  // ---- Int ----
  Future<void> setInt(String key, int value) async {
    await ensureReady();
    await _box!.put(key, value);
  }

  Future<int?> getInt(String key) async {
    await ensureReady();
    final v = _box!.get(key);
    if (v is int) return v;
    return null;
  }
}
