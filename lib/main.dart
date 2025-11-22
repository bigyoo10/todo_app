import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/splash_gate.dart';

import 'services/local_db_service.dart';
import 'services/prefs_service.dart';
import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/notif_router.dart';
import 'pages/settings_page.dart';
import 'providers/theme_provider.dart'; // ✅ 추가

/// 앱 전체에서 사용하는 전역 navigatorKey (NotificationService에서 사용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService.navKey = navigatorKey;
  await LocalDbService.instance.init();
  await PrefsService.instance.init();
  await NotificationService.instance.init();
  // Request notification permission on first launch
  final asked = await PrefsService.instance.getBool('notifAsked') ?? false;
  if (!asked) {
    final granted = await NotificationService.instance.requestPermissionIfNeeded(force: true);
    await PrefsService.instance.setBool('notifAsked', true);
    await PrefsService.instance.setBool('notifGranted', granted);
  }
  runApp(const ProviderScope(child: MyApp()));
}

/// 전체 앱을 감싸는 루트 위젯 (테마/라우팅 설정)
class MyApp extends ConsumerWidget { // ✅ ConsumerWidget로 변경
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider); // ✅ 앱 상태로 제어

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode, // ✅ system/light/dark 중 선택값 적용
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
      ),
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/notif': (context) {
          final payload = ModalRoute.of(context)?.settings.arguments as String?;
          return NotifRouterPage(payload: payload);
        },
      },
      home: SplashGate(home: const HomePage()),
    );
  }
}
