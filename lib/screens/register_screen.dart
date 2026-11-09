// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: register screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import '../core/auth_api.dart';

/// RegisterScreen: 해당 기능을 표시하는 화면 위젯입니다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// _RegisterScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();

  bool isLoading = false;

  /// register: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> register() async {
    setState(() {
      isLoading = true;
    });

    try {
      await AuthApi.register(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        nickname: nicknameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
      );

      Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
            const SizedBox(height: 16),

            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}