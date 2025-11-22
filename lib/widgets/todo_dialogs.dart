import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter, MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../utils/constants.dart';

const String defaultCategory = '기타';
const int defaultPriority = 0;

/// 새 Todo를 추가하기 위한 전체 화면 다이얼로그를 엽니다.
Future<void> showAddDialog(BuildContext context, WidgetRef ref) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => _AddTodoPage(ref: ref),
      transitionsBuilder: (ctx, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      fullscreenDialog: true,
    ),
  );
}

/// 기존 Todo를 수정하기 위한 전체 화면 다이얼로그를 엽니다.
Future<void> showEditDialog(BuildContext context, WidgetRef ref, Todo todo, int index) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => _EditTodoPage(ref: ref, todo: todo, index: index),
      transitionsBuilder: (ctx, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      fullscreenDialog: true,
    ),
  );
}

// ===== 날짜/시간 공통 =====
Future<DateTime?> _pickDateMaterial(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 2),
  );
}

Future<DateTime?> _pickDateCupertino(BuildContext context, DateTime initial) async {
  final cs = Theme.of(context).colorScheme;
  DateTime temp = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SizedBox(
      height: 320,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('날짜 선택',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              )),
          Expanded(
            child: cupertino.CupertinoDatePicker(
              mode: cupertino.CupertinoDatePickerMode.date,
              initialDateTime: temp,
              onDateTimeChanged: (dt) => temp = dt,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('확인')),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) async {
  return showTimePicker(
    context: context,
    initialTime: initial,
    initialEntryMode: TimePickerEntryMode.input,
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );
}

DateTime combineDateTime(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

String formatTimeAmPm(TimeOfDay t) =>
    DateFormat('h:mm a').format(DateTime(0, 1, 1, t.hour, t.minute));

// ===== Glass Container (테마 기반) =====
class _GlassScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const _GlassScaffold({required this.title, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.surfaceVariant, cs.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: onSurface.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_ios_new),
                              ),
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: onSurface,
                                ),
                              ),
                              const Spacer(),
                              ...(actions ?? []),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: onSurface)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChipsBar extends StatelessWidget {
  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelected;
  const _ChipsBar({required this.chips, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        final sel = c == selected;
        return ChoiceChip(
          label: Text(c),
          selected: sel,
          onSelected: (_) => onSelected(c),
          shape: const StadiumBorder(),
          selectedColor: cs.primary.withOpacity(0.14),
          side: BorderSide(color: onSurface.withOpacity(0.08)),
          backgroundColor: cs.surfaceVariant.withOpacity(0.35),
          labelStyle: TextStyle(
            fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
            color: sel ? cs.primary : onSurface,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        );
      }).toList(),
    );
  }
}

class _PrioritySegment extends StatelessWidget {
  final int value; // 0/1/2
  final ValueChanged<int> onChanged;
  const _PrioritySegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ToggleButtons(
      isSelected: [0,1,2].map((i) => i == value).toList(),
      onPressed: (i) => onChanged(i),
      borderRadius: BorderRadius.circular(14),
      constraints: const BoxConstraints(minHeight: 38, minWidth: 84),
      selectedColor: cs.primary,
      fillColor: cs.primary.withOpacity(0.12),
      children: const [
        Text('Low', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('Medium', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('High', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ===== Add =====
class _AddTodoPage extends StatefulWidget {
  final WidgetRef ref;
  const _AddTodoPage({required this.ref});
  @override
  State<_AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<_AddTodoPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _category = defaultCategory;
  int _priority = defaultPriority;
  bool _alarmEnabled = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  void _save() async {
    final t = _title.text.trim();
    final d = _desc.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력하세요')));
      return;
    }

    DateTime? alarmAt = _alarmEnabled ? combineDateTime(_date, _time) : null;

    // ✅ UX: 과거/동시각 저장 시 +1분 보정
    final now = DateTime.now();
    if (alarmAt != null && !alarmAt.isAfter(now)) {
      alarmAt = now.add(const Duration(minutes: 1));
    }

    await widget.ref.read(todoListProvider.notifier).addTodo(
      Todo(
        title: t,
        description: d,
        createdAt: DateTime.now(),
        category: _category,
        priority: _priority,
        notificationTime: alarmAt,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return _GlassScaffold(
      title: 'Add New Task',
      actions: [TextButton(onPressed: _save, child: const Text('Add'))],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          _Section(
            title: 'Basic',
            child: Column(
              children: [
                _field(_title, hint: 'Title', maxLen: 15),
                const SizedBox(height: 10),
                _field(_desc, hint: 'Description', maxLines: 3, maxLen: 20),
              ],
            ),
          ),
          _Section(
            title: 'Category',
            child: _ChipsBar(
              chips: categoryList,
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
          ),
          _Section(
            title: 'Priority',
            child: _PrioritySegment(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
          ),
          _Section(
            title: 'Alarm',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const SizedBox.shrink(),
                  value: _alarmEnabled,
                  onChanged: (v) => setState(() => _alarmEnabled = v),
                ),
                if (_alarmEnabled)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(DateFormat('yyyy.MM.dd').format(_date),
                              style: TextStyle(color: onSurface.withOpacity(0.9))),
                          onPressed: () async {
                            final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
                            final picked = isIOS
                                ? await _pickDateCupertino(context, _date)
                                : await _pickDateMaterial(context, _date);
                            if (picked != null) setState(() => _date = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(formatTimeAmPm(_time),
                              style: TextStyle(color: onSurface.withOpacity(0.9))),
                          onPressed: () async {
                            final picked = await _pickTime(context, _time);
                            if (picked != null) setState(() => _time = picked);
                          },
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, {required String hint, int maxLines = 1, int? maxLen}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: c,
      maxLines: maxLines,
      inputFormatters: [
        if (maxLen != null)
          LengthLimitingTextInputFormatter(maxLen, maxLengthEnforcement: MaxLengthEnforcement.enforced),
      ],
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ===== Edit =====
class _EditTodoPage extends StatefulWidget {
  final WidgetRef ref;
  final Todo todo;
  final int index;
  const _EditTodoPage({required this.ref, required this.todo, required this.index});
  @override
  State<_EditTodoPage> createState() => _EditTodoPageState();
}

class _EditTodoPageState extends State<_EditTodoPage> {
  late final TextEditingController _title = TextEditingController(text: widget.todo.title);
  late final TextEditingController _desc = TextEditingController(text: widget.todo.description);
  late String _category = widget.todo.category ?? defaultCategory;
  late int _priority = widget.todo.priority ?? defaultPriority;
  late bool _alarmEnabled = widget.todo.notificationTime != null;
  late DateTime _date = widget.todo.notificationTime ?? DateTime.now();
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.todo.notificationTime ?? DateTime.now());

  void _save() async {
    final t = _title.text.trim();
    final d = _desc.text.trim();

    DateTime? alarmAt = _alarmEnabled ? combineDateTime(_date, _time) : null;

    // ✅ UX: 과거/동시각 저장 시 +1분 보정
    final now = DateTime.now();
    if (alarmAt != null && !alarmAt.isAfter(now)) {
      alarmAt = now.add(const Duration(minutes: 1));
    }

    final updated = Todo(
      title: t,
      description: d,
      createdAt: widget.todo.createdAt,
      category: _category,
      priority: _priority,
      notificationTime: alarmAt,
      isCompleted: widget.todo.isCompleted,
      completedAt: widget.todo.completedAt,
    );
    await widget.ref.read(todoListProvider.notifier).updateTodo(widget.index, updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return _GlassScaffold(
      title: 'Edit Task',
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          _Section(
            title: 'Basic',
            child: Column(
              children: [
                _field(_title, hint: 'Title', maxLen: 15),
                const SizedBox(height: 10),
                _field(_desc, hint: 'Description', maxLines: 3, maxLen: 20),
              ],
            ),
          ),
          _Section(
            title: 'Category',
            child: _ChipsBar(
              chips: categoryList,
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
          ),
          _Section(
            title: 'Priority',
            child: _PrioritySegment(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
          ),
          _Section(
            title: 'Alarm',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const SizedBox.shrink(),
                  value: _alarmEnabled,
                  onChanged: (v) => setState(() => _alarmEnabled = v),
                ),
                if (_alarmEnabled)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(DateFormat('yyyy.MM.dd').format(_date),
                              style: TextStyle(color: onSurface.withOpacity(0.9))),
                          onPressed: () async {
                            final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
                            final picked = isIOS
                                ? await _pickDateCupertino(context, _date)
                                : await _pickDateMaterial(context, _date);
                            if (picked != null) setState(() => _date = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(formatTimeAmPm(_time),
                              style: TextStyle(color: onSurface.withOpacity(0.9))),
                          onPressed: () async {
                            final picked = await _pickTime(context, _time);
                            if (picked != null) setState(() => _time = picked);
                          },
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, {required String hint, int maxLines = 1, int? maxLen}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: c,
      maxLines: maxLines,
      inputFormatters: [
        if (maxLen != null)
          LengthLimitingTextInputFormatter(maxLen, maxLengthEnforcement: MaxLengthEnforcement.enforced),
      ],
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
