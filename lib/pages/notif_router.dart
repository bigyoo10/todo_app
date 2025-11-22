import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/focus_provider.dart';
import 'home_page.dart';

/// /notif 라우트: 알림 payload("nid:123")를 파싱해 Provider에 저장 후 HomePage로 이동
class NotifRouterPage extends ConsumerStatefulWidget {
  const NotifRouterPage({super.key, this.payload});
  final String? payload;

  @override
  ConsumerState<NotifRouterPage> createState() => _NotifRouterPageState();
}

class _NotifRouterPageState extends ConsumerState<NotifRouterPage> {
  @override
  void initState() {
    super.initState();

    // ❗ Provider 수정은 빌드가 끝난 '다음 프레임'에 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = widget.payload ?? '';
      final nid = p.startsWith('nid:') ? int.tryParse(p.substring(4)) : null;

      if (nid != null) {
        ref.read(focusedNotificationIdProvider.notifier).state = nid;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
