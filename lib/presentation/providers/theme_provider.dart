import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/storage_repository.dart';
import 'providers.dart';

/// Стан теми
class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({
    this.themeMode = ThemeMode.system,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Theme State Notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  final StorageRepository _storageRepository;

  ThemeNotifier(this._storageRepository) : super(const ThemeState()) {
    _loadThemeMode();
  }

  /// Завантаження збереженого режиму теми
  Future<void> _loadThemeMode() async {
    final themeModeString = _storageRepository.getThemeMode();
    final themeMode = _themeModeFromString(themeModeString);

    state = state.copyWith(themeMode: themeMode);
  }

  /// Зміна режиму теми
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _storageRepository.setThemeMode(_themeModeToString(themeMode));
  }

  /// Конвертація ThemeMode в String
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Конвертація String в ThemeMode
  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// Theme State Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(ref.watch(storageRepositoryProvider));
});
