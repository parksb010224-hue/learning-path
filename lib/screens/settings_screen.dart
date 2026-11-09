// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: settings screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

/// SettingsScreen: 해당 기능을 표시하는 화면 위젯입니다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// _SettingsScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;

  /// _select: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _select(ThemeMode mode) async {
    setState(() => _saving = true);
    try {
      await ThemeController.instance.setMode(mode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테마 설정을 저장하지 못했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, child) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('화면 테마', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('선택한 테마는 다음 실행에도 유지됩니다.'),
            const SizedBox(height: 16),
            for (final entry in const {
              ThemeMode.light: '라이트 모드',
              ThemeMode.dark: '다크 모드',
              ThemeMode.system: '시스템 설정 따르기',
            }.entries)
              ListTile(
                title: Text(entry.value),
                leading: Icon(entry.key == ThemeMode.dark
                    ? Icons.dark_mode
                    : entry.key == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto),
                trailing: ThemeController.instance.mode == entry.key
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                enabled: !_saving,
                onTap: () => _select(entry.key),
              ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// ThemeSettingsButton: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ThemeSettingsButton extends StatelessWidget {
  const ThemeSettingsButton({super.key});

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) => IconButton(
    tooltip: '테마 설정',
    icon: const Icon(Icons.settings),
    onPressed: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const SettingsScreen())),
  );
}
