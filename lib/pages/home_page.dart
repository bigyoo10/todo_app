import '../services/prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/focus_provider.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_dialogs.dart';
import '../widgets/highlight_pulse.dart';
import 'stats_page.dart';


/// 메인 화면: 카테고리별 Todo 목록과 통계/설정 진입을 제공하는 화면입니다.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final asked = await PrefsService.instance.getBool('notifAsked') ?? false;
      final granted = await PrefsService.instance.getBool('notifGranted') ?? true;
      if (asked && !granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 꺼져 있어요. 설정에서 켜면 일정을 제때 받을 수 있어요.')),
        );
      }
    });
  }

  String _selected = '전체';

  // 인덱스 스크롤 (GlobalKey 사용 안 함)
  final _scrollController = ScrollController();
  int? _highlightNid;

  // 카드 1개 높이(패딩 포함) – 필요 시 88~110 사이로 미세 조정
  static const double _itemExtent = 94.0;

  List<String> _buildCategories(List<Todo> todos) {
    final set = <String>{};
    for (final t in todos) {
      final c = (t.category ?? '').trim().isEmpty ? '기타' : t.category!.trim();
      set.add(c);
    }
    return ['전체', ...set.toList()..sort()];
  }

  List<Todo> _filtered(List<Todo> todos) {
    if (_selected == '전체') return todos;
    return todos.where((t) {
      final c = (t.category ?? '').trim().isEmpty ? '기타' : t.category!.trim();
      return c == _selected;
    }).toList();
  }

  Future<void> _scrollToIndex(int index) async {
    final offset = (index * _itemExtent).toDouble().clamp(
      0.0,
      _scrollController.position.hasContentDimensions
          ? _scrollController.position.maxScrollExtent
          : double.infinity,
    );
    await _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoListProvider);
    final categories = _buildCategories(todos);
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    // 알림에서 전달된 nid를 감지 → 카테고리 자동 전환 → 인덱스 스크롤 & 강조
    final focusedNid = ref.watch(focusedNotificationIdProvider);
    if (focusedNid != null && focusedNid != _highlightNid) {
      _highlightNid = focusedNid;

      // 1) 전체 목록에서 대상 찾고 카테고리 자동 전환
      final idxAll = todos.indexWhere((t) => t.notificationId == focusedNid);
      if (idxAll != -1) {
        final t = todos[idxAll];
        final cat = ((t.category ?? '').trim().isEmpty) ? '기타' : t.category!.trim();
        if (_selected != '전체' && _selected != cat) {
          setState(() => _selected = cat);
        }
      }

      // 2) 다음 프레임에서 필터링 리스트 기준으로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final current = ref.read(todoListProvider);
        final filtered = _filtered(current);
        final index = filtered.indexWhere((t) => t.notificationId == focusedNid);

        if (index != -1) {
          await _scrollToIndex(index);
        }

        // 3) 2초 뒤 하이라이트 해제
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _highlightNid == focusedNid) {
            setState(() => _highlightNid = null);
          }
        });

        // 4) 1회성 초기화
        ref.read(focusedNotificationIdProvider.notifier).state = null;
      });
    }

    final items = _filtered(todos);

    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now);
    final dateText = DateFormat('MMMM d').format(now);
    final dayNum = DateFormat('d').format(now);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => showAddDialog(context, ref),
        backgroundColor: cs.primary,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ===== 헤더 =====
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 190,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,

            actions: [
              IconButton(
                tooltip: '설정',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
              IconButton(
                tooltip: '통계',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                ),
                icon: const Icon(Icons.insights_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withValues(alpha: 0.60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'To Do',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dayNum,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== 고정 Chip 필터 =====
          SliverPersistentHeader(
            pinned: true,
            delegate: _ChipHeaderDelegate(
              categories: categories,
              selected: _selected,
              onSelected: (v) => setState(() => _selected = v),
            ),
          ),

          // ===== 리스트 =====
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _selected == '전체'
                      ? '할 일이 비어 있어요'
                      : "'$_selected' 카테고리에 할 일이 없어요",
                  style: TextStyle(color: onSurface.withValues(alpha: 0.45)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final todo = items[index];
                  final originalIndex = todos.indexOf(todo);
                  final isHighlighted =
                  (todo.notificationId != null && todo.notificationId == _highlightNid);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: HighlightPulse(
                      isActive: isHighlighted,
                      borderRadius: BorderRadius.circular(14),
                      child: TodoCard(
                        todo: todo,
                        onTap: () => showEditDialog(context, ref, todo, originalIndex),
                        onToggleComplete: () => ref
                            .read(todoListProvider.notifier)
                            .toggleComplete(originalIndex),
                        onDelete: () => ref
                            .read(todoListProvider.notifier)
                            .deleteTodo(originalIndex),
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _ChipHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  _ChipHeaderDelegate({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = categories[i];
          final sel = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: sel,
            onSelected: (_) => onSelected(label),
            shape: const StadiumBorder(),
            side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
            selectedColor: cs.primary.withValues(alpha: 0.14),
            backgroundColor: cs.surfaceVariant.withValues(alpha: 0.35),
            labelStyle: TextStyle(
              fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
              color: sel ? cs.primary : onSurface,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ChipHeaderDelegate old) =>
      old.categories != categories || old.selected != selected;
}