import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 알림 탭으로 앱에 진입했을 때 포커스해야 할 Todo의 notificationId를 보관
final focusedNotificationIdProvider = StateProvider<int?>((ref) => null);
