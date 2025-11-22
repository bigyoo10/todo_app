import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';

/// ThemeMode(system/light/dark)를 Hive에 저장/복원하는 Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    await PrefsService.instance.ensureReady();
    final idx = await PrefsService.instance.getInt('themeMode');
    if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
      state = ThemeMode.values[idx];
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await PrefsService.instance.setInt('themeMode', mode.index);
  }
}

/// 앱 전역 테마 모드 (system/light/dark)를 보관 + 영구 저장
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
