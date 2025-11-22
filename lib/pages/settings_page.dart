import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notif_settings_provider.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';

/// 알림/테마 등 앱 전역 설정을 관리하는 화면입니다.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notifSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeCtl = ref.read(themeModeProvider.notifier);

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // 테마 모드
          const ListTile(
            title: Text('테마'),
            subtitle: Text('라이트/다크/시스템 기본값 설정'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('시스템')),
                ButtonSegment(value: ThemeMode.light,  label: Text('라이트')),
                ButtonSegment(value: ThemeMode.dark,   label: Text('다크')),
              ],
              selected: {themeMode},
              onSelectionChanged: (sel) async {
                final m = sel.first;
                await themeCtl.set(m);
              },
            ),
          ),
          const Divider(height: 24),

          // 알림 허용 토글
          SwitchListTile(
            title: const Text('알림 허용'),
            subtitle: const Text('앱 내 일정/할 일 알림을 사용합니다'),
            value: settings.enabled,
            onChanged: (v) async => await ref.read(notifSettingsProvider.notifier).setEnabled(v),
          ),

          // 시스템 알림 권한 상태 + 요청
          ListTile(
            title: const Text('시스템 알림 권한 상태'),
            subtitle: FutureBuilder<bool>(
              future: NotificationService.instance.canNotify(),
              builder: (context, snap) {
                if (!snap.hasData) return const Text('확인 중…');
                return Text(snap.data! ? '허용됨' : '거부됨');
              },
            ),
            trailing: TextButton(
              child: const Text('권한 요청'),
              onPressed: () async {
                final ok = await NotificationService.instance.requestPermissionIfNeeded(force: true);
                if (!ok) {
                  NotificationService.instance.showSnack('알림 권한이 거절됐어요. 시스템 설정에서 직접 켜주세요.');
                } else {
                  NotificationService.instance.showSnack('알림 권한이 허용됐어요!');
                }
              },
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '참고: Android 13 이상에서는 시스템 알림 권한이 꺼져 있으면 알림이 표시되지 않아요.\n'
              '정확 알람(Exact alarm)이 필요한 경우 별도 설정이 필요할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
