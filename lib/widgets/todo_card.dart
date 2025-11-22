import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

/// 단일 Todo 아이템을 카드 형태로 표시하는 위젯입니다.
class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback? onDelete;
  final bool showCheckbox;
  final bool isSelected;

  static const double _kCardHeight = 136;
  static const double _kSidePad = 12;
  static const double _kInnerPad = 12;
  static const double _kLeadWidth = 48;
  static const double _kDescHeight = 32;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggleComplete,
    this.onDelete,
    this.showCheckbox = true,
    this.isSelected = false,
  });

  String _priorityText(int? p) => p == 2 ? '높음' : (p == 1 ? '보통' : '낮음');
  Color _priorityBg(int? p) => p == 2
      ? Colors.red.withOpacity(0.12)
      : (p == 1 ? Colors.orange.withOpacity(0.12) : Colors.green.withOpacity(0.12));
  Color _priorityFg(int? p) => p == 2
      ? Colors.red.shade700
      : (p == 1 ? Colors.orange.shade700 : Colors.green.shade700);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category =
    (todo.category ?? '').trim().isEmpty ? '기타' : todo.category!.trim();
    final priority = todo.priority ?? 0;

    return Dismissible(
      key: ValueKey(todo.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('삭제'),
            content: const Text('이 할 일을 삭제할까요?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('삭제')),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        height: _kCardHeight,
        margin: EdgeInsets.symmetric(horizontal: _kSidePad, vertical: 8),
        decoration: BoxDecoration(
          color: todo.isCompleted
              ? Colors.green.withOpacity(0.07)
              : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.55)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(_kInnerPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 왼쪽: 완료 토글
                SizedBox(
                  width: _kLeadWidth,
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        todo.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: todo.isCompleted
                            ? Colors.green
                            : theme.colorScheme.primary.withOpacity(0.9),
                        size: 26,
                      ),
                      onPressed: onToggleComplete,
                      tooltip: todo.isCompleted ? '완료 취소' : '완료로 표시',
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 가운데: 제목/설명/알림
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color:
                          todo.isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: _kDescHeight,
                        child: (todo.description.isNotEmpty)
                            ? Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 6),
                      if (todo.notificationTime != null)
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MM/dd HH:mm')
                                  .format(todo.notificationTime!),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 오른쪽: 우상단 칩 + 하단 화살표
                ConstrainedBox(
                  constraints:
                  const BoxConstraints(minWidth: 90, maxWidth: 128),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _priorityBg(priority),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag_rounded,
                                    size: 12, color: _priorityFg(priority)),
                                const SizedBox(width: 4),
                                Text(
                                  _priorityText(priority),
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _priorityFg(priority),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              category,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
