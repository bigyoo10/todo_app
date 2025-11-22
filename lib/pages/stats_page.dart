import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// 오늘/주간/월간 기준으로 Todo 통계를 보여주는 화면입니다.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _tab = 0; // 0 Today, 1 Week, 2 Month

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoListProvider);

    final today = _rangeAgg(todos, days: 1);
    final week = _rangeAgg(todos, days: 7);
    final month = _rangeAgg(todos, days: 30);

    // ★ 테마 참조
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final dataset = [_Stat(today), _Stat(week), _Stat(month)][_tab];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SegmentTab(
            value: _tab,
            options: const ['Today', 'Week', 'Month'],
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),

          // 간단한 도넛(원형 진행률)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ★ 제목: onSurface
                  Text(
                    ['Today', 'Week', 'Month'][_tab],
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: dataset.rate,
                              strokeWidth: 16,
                              // (선택) 다크 대응을 더 예쁘게 하고 싶다면:
                              backgroundColor: cs.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(cs.primary),
                            ),
                          ),
                          // ★ 퍼센트 텍스트: onSurface
                          Text(
                            '${(dataset.rate * 100).toStringAsFixed(0)}%',
                            style: tt.headlineSmall?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // ★ 범례 텍스트는 onSurfaceVariant로
                      _LegendDot(text: 'Completed', color: cs.onSurfaceVariant),
                      const SizedBox(width: 16),
                      _LegendDot(text: 'Incomplete', color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.list_alt_rounded,
                  label: 'Total Tasks',
                  value: dataset.total.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.priority_high_rounded,
                  label: 'High Priority',
                  value: dataset.highPriority.toString(),
                  color: Colors.orange, // 원하면 cs.secondary 로도 가능
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _Agg _rangeAgg(List<Todo> todos, {required int days}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final inRange = todos.where((t) =>
    t.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
        t.createdAt.isBefore(end.add(const Duration(seconds: 1))));
    final total = inRange.length;
    final completed = inRange.where((t) => t.isCompleted == true).length;
    final high = inRange.where((t) => (t.priority ?? 0) == 2).length;
    final rate = total == 0 ? 0.0 : completed / total;
    return _Agg(total: total, completed: completed, rate: rate, highPriority: high);
  }
}

class _Agg {
  final int total;
  final int completed;
  final double rate;
  final int highPriority;
  _Agg({required this.total, required this.completed, required this.rate, required this.highPriority});
}

class _Stat {
  final int total, highPriority;
  final double rate;
  _Stat(_Agg a)
      : total = a.total,
        highPriority = a.highPriority,
        rate = a.rate;
}

class _SegmentTab extends StatelessWidget {
  final int value;
  final List<String> options;
  final ValueChanged<int> onChanged;
  const _SegmentTab({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: ToggleButtons(
        isSelected: List.generate(options.length, (i) => i == value),
        onPressed: onChanged,
        borderRadius: BorderRadius.circular(18),
        constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
        selectedColor: cs.primary,
        fillColor: cs.primary.withOpacity(0.12),
        focusColor: cs.primary.withOpacity(0.18),
        hoverColor: cs.primary.withOpacity(0.08),
        splashColor: cs.primary.withOpacity(0.16),
        borderColor: cs.outlineVariant,
        selectedBorderColor: cs.primary,
        children: options
            .map((t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          // ★ 텍스트: 테마 기반(색 직접 지정 X)
          child: Text(t, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ))
            .toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _MetricCard({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final c = color ?? cs.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c),
            const SizedBox(height: 10),
            // ★ 값: onSurface
            Text(
              value,
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            // ★ 라벨: onSurfaceVariant
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String text;
  final Color color;
  const _LegendDot({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        // ★ 범례 텍스트: onSurfaceVariant
        Text(
          text,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
