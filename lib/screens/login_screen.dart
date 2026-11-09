// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: login screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'settings_screen.dart';
import 'package:flutter/material.dart';
import '../core/auth_api.dart';
import 'problem_list_screen.dart';
import 'register_screen.dart';

/// LoginScreen: 해당 기능을 표시하는 화면 위젯입니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<LoginScreen> createState() => _LoginScreenState();
}

/// _LoginScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  /// login: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthApi.login(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      final int userId = result['user_id'];

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProblemListScreen(userId: userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [ThemeSettingsButton()]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Learning Path',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('로그인'),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}