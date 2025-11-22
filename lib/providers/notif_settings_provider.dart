import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';
import '../services/notification_service.dart';

/// 알림 관련 설정 값 (현재는 on/off 정도만 관리)
class NotifSettings {
  final bool enabled;
  const NotifSettings({required this.enabled});

  NotifSettings copyWith({bool? enabled}) =>
      NotifSettings(enabled: enabled ?? this.enabled);
}

/// 알림 설정을 관리하는 StateNotifier (Hive에 영구 저장)
final notifSettingsProvider =
    StateNotifierProvider<NotifSettingsNotifier, NotifSettings?>((ref) {
  return NotifSettingsNotifier()..init();
});

class NotifSettingsNotifier extends StateNotifier<NotifSettings?> {
  NotifSettingsNotifier() : super(null);

  /// 앱 시작 시 저장된 알림 설정 불러오기
  Future<void> init() async {
    await PrefsService.instance.ensureReady();
    final enabled =
        await PrefsService.instance.getBool('notifEnabled') ?? true;
    state = NotifSettings(enabled: enabled);
  }

  /// 토글 스위치에서 알림 사용 여부 변경
  Future<void> setEnabled(bool value) async {
    // 켜는 경우에는 실제 시스템 알림 권한도 함께 확인/요청
    if (value) {
      final granted = await NotificationService.instance
          .requestPermissionIfNeeded(force: true);
      if (!granted) {
        NotificationService.instance.showSnack(
          '알림 권한이 거절되어 설정을 변경할 수 없어요. 시스템 설정에서 켜주세요.',
        );
        return;
      }
    }

    final current = state ?? const NotifSettings(enabled: true);
    state = current.copyWith(enabled: value);
    await PrefsService.instance.setBool('notifEnabled', value);
  }
}
