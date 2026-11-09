// 파일 역할: 앱 전체의 색상·테마 상태 관리: theme controller
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ThemeController: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ThemeController extends ChangeNotifier {
  static final instance = ThemeController();
  static const _key = 'learning_path_theme_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  ThemeMode mode = ThemeMode.light;

  /// load: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _key);
      mode = ThemeMode.values.firstWhere(
        (value) => value.name == saved,
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      // Storage unavailable: the app can still start with its default theme.
      mode = ThemeMode.light;
    }
  }

  /// setMode: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> setMode(ThemeMode value) async {
    // Commit only after persistence succeeds so failed saves are retryable.
    await _storage.write(key: _key, value: value.name);
    mode = value;
    notifyListeners();
  }
}
