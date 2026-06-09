import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'app_theme_mode';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      if (value == 'dark') emit(ThemeMode.dark);
      if (value == 'light') emit(ThemeMode.light);
    } catch (_) {
      // Platform channel unavailable on hot restart — silently keep default
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  void toggle() {
    if (state == ThemeMode.dark) {
      setMode(ThemeMode.light);
    } else {
      setMode(ThemeMode.dark);
    }
  }
}
