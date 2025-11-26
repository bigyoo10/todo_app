import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알림 플러그인을 래핑한 서비스.
///
/// - [init]에서 플러그인을 초기화하고 타임존 정보를 로드합니다.
/// - [scheduleNotification]으로 특정 시각에 알림을 예약합니다.
/// - [cancelNotification]으로 예약된 알림을 취소합니다.
/// - 알림을 탭하면 '/notif' 라우트로 이동하며 payload에 'nid:알림ID'를 전달합니다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 알림 탭 시 네비게이션에 사용될 전역 navigatorKey
  static GlobalKey<NavigatorState>? navKey;

  bool _initialized = false;
  bool _deniedBannerShown = false;

  /// 플러그인 초기화 + 타임존 초기화
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@drawable/android12splash');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && navKey?.currentState != null) {
          navKey!.currentState!.pushNamed('/notif', arguments: payload);
        }
      },
    );

    _initialized = true;
  }

  /// 현재 알림을 표시할 수 있는지(시스템 권한 기준) 확인.
  Future<bool> canNotify() async {
    await init();
    bool result = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled == false) {
        result = false;
      }
    }
    // iOS는 requestPermissions에서 거절 여부를 반환하므로 여기서는 true 가정
    return result;
  }

  /// 필요 시 시스템 알림 권한을 요청.
  ///
  /// [force]가 true면 이미 권한이 있는 경우에도 한 번 더 요청을 시도합니다(Android 기준).
  Future<bool> requestPermissionIfNeeded({bool force = false}) async {
    await init();
    bool granted = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (force || (enabled == false)) {
        final ok = await android.requestNotificationsPermission();
        granted = (ok ?? false);
      }
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      if (ok != null) granted = granted && ok;
    }

    return granted;
  }

  /// ScaffoldMessenger를 통해 간단한 스낵바 메시지 표시
  void showSnack(String msg) {
    try {
      final ctx = navKey?.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      // context가 없을 수 있으므로 실패해도 앱이 죽지 않도록 방어
    }
  }

  /// 지정된 [id]로 [when] 시각에 알림 예약.
  ///
  /// - 과거 시간이 들어오면 현재 시각 + 1분으로 보정합니다.
  /// - Android 13 이상에서 exact alarm 권한이 없는 경우, inexactAllowWhileIdle 모드로 예약합니다.
  Future<void> scheduleNotification(
    int id,
    String title,
    DateTime when,
  ) async {
    await init();
    final granted = await requestPermissionIfNeeded();
    if (!granted) {
      _showDeniedBannerOnce();
      return;
    }

    // 과거 시각 -> 최소 1분 뒤로 보정
    final now = DateTime.now();
    if (!when.isAfter(now)) {
      when = now.add(const Duration(minutes: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_channel',
        'Todo 알림',
        channelDescription: '할 일/일정 알림 채널',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final tzTime = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      '',
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // iOS 10 미만 관련 옵션이라 현재 버전에서는 아예 사라진 파라미터라서 제거
      // uiLocalNotificationDateInterpretation: ...  <= 삭제
      matchDateTimeComponents: null,
      payload: 'nid:$id',
    );
  }

  /// 예약된 알림 취소
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[Notif] cancel failed: $e');
    }
  }

  void _showDeniedBannerOnce() {
    if (_deniedBannerShown) return;
    _deniedBannerShown = true;

    try {
      final ctx = navKey?.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
              '알림 권한이 꺼져 있어요. 설정에서 켜면 일정 알림을 받을 수 있어요.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      // context가 없을 수 있으므로 실패해도 무시
    }
  }
}
