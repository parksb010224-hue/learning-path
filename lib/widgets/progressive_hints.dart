// 파일 역할: 단계별로 공개되는 힌트 UI 컴포넌트
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ProgressiveHints: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ProgressiveHints extends StatefulWidget {
  final List<String> hints;
  const ProgressiveHints({super.key, required this.hints});
  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<ProgressiveHints> createState() => _ProgressiveHintsState();
}

/// _ProgressiveHintsState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _ProgressiveHintsState extends State<ProgressiveHints> {
  int _visibleCount = 1;
  @override
  /// didUpdateWidget: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void didUpdateWidget(covariant ProgressiveHints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.hints, widget.hints)) _visibleCount = 1;
  }
  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('단계별 힌트', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('$_visibleCount/${widget.hints.length} 공개 · 먼저 생각해본 뒤 다음 힌트를 열어보세요.'),
      const SizedBox(height: 12),
      for (var index = 0; index < widget.hints.length; index++)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(index < _visibleCount ? Icons.lightbulb_outline : Icons.lock_outline,
                  color: index < _visibleCount ? Colors.orange : Colors.grey),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('힌트 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (index < _visibleCount)
                  Text(widget.hints[index].trim().isEmpty ? '제공된 힌트가 없습니다.' : widget.hints[index])
                else
                  const Text('아직 공개하지 않은 힌트입니다.'),
              ])),
            ]),
          ),
        ),
      if (_visibleCount < widget.hints.length)
        OutlinedButton.icon(
          onPressed: () => setState(() => _visibleCount++),
          icon: const Icon(Icons.lock_open),
          label: Text('힌트 ${_visibleCount + 1} 보기'),
        )
      else
        const Text('모든 힌트를 확인했습니다.'),
      const SizedBox(height: 16),
    ]);
  }
}
