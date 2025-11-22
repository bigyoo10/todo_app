// splash_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// 앱 시작 시 스플래시 이미지를 잠깐 보여주고 실제 home 위젯으로 진입시키는 게이트.
class SplashGate extends StatefulWidget {
  final Widget home;
  const SplashGate({super.key, required this.home});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // 필요하면 여기서 초기화 작업 await
    await Future.delayed(const Duration(milliseconds: 700));
    await _fade.forward(); // 이미지가 서서히 사라짐
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.home),
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/splash/splash_full.png', fit: BoxFit.cover),
        FadeTransition(
          opacity: _fade,
          child: const ColoredBox(color: Colors.black54), // 살짝 어둡게 페이드
        ),
      ]),
    );
  }
}
