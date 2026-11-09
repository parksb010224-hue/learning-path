// 파일 역할: Flutter 단위·위젯 테스트: widget test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';
import 'package:untitled/theme/theme_controller.dart';

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  testWidgets('Theme changes preserve the open route', (tester) async {
    final controller = ThemeController.instance;
    controller.mode = ThemeMode.light;
    await tester.pumpWidget(const MyApp());
    expect(find.text('로그인'), findsOneWidget);
    await tester.tap(find.byTooltip('테마 설정'));
    await tester.pumpAndSettle();
    expect(find.text('화면 테마'), findsOneWidget);
    controller.mode = ThemeMode.dark;
    controller.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('화면 테마'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('화면 테마'))).brightness,
        Brightness.dark);
    controller.mode = ThemeMode.light;
    controller.notifyListeners();
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('화면 테마'))).brightness,
        Brightness.light);
  });
}
