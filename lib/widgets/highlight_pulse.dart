import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 세련된 하이라이트 효과:
/// - 부드러운 halo 그림자
/// - 좌측 액센트 바
/// - 미세한 scale 업
/// isActive가 true일 때 900ms 동안 펄스 후 자연스레 정착
class HighlightPulse extends StatefulWidget {
  final bool isActive;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const HighlightPulse({
    super.key,
    required this.isActive,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<HighlightPulse> createState() => _HighlightPulseState();
}

class _HighlightPulseState extends State<HighlightPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

    if (widget.isActive) _c.forward();
  }

  @override
  void didUpdateWidget(covariant HighlightPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _c.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _c.animateTo(1, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value;
        final opacity = (1 - t);
        final blur = 24.0 * (1 - t) + 6.0;
        final spread = 1.5 * (1 - t);
        final scale = 1.0 + 0.015 * (1 - t);

        return Stack(
          children: [
            // 좌측 액센트 바
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: widget.isActive ? 0.9 : 0,
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 본문(halo + scale)
            Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.28 * opacity),
                      blurRadius: blur,
                      spreadRadius: spread,
                      offset: Offset(0, math.max(2, 8 * (1 - t))),
                    ),
                  ],
                  border: widget.isActive
                      ? Border.all(color: primary.withOpacity(0.9 * opacity), width: 1)
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
