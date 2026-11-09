// 파일 역할: Flutter 앱 시작점: 테마와 화면 네비게이션을 초기화
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const MyApp());
}

/// MyApp: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Learning Path',
        theme: AppTheme.build(Brightness.light),
        darkTheme: AppTheme.build(Brightness.dark),
        themeMode: ThemeController.instance.mode,
        home: const LoginScreen(),
      ),
    );
  }
}
