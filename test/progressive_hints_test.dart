// 파일 역할: Flutter 단위·위젯 테스트: progressive hints test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/progressive_hints.dart';
/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  testWidgets('only reveals hints in order and survives parent rebuild', (tester) async {
    /// view: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
    Widget view(int submissionId) => MaterialApp(home: Scaffold(body:
      ProgressiveHints(key: ValueKey(submissionId), hints: const ['first secret', 'second secret', 'third secret'])));
    await tester.pumpWidget(view(1));
    expect(find.text('first secret'), findsOneWidget);
    expect(find.text('second secret'), findsNothing);
    expect(find.text('third secret'), findsNothing);
    expect(find.text('힌트 3 보기'), findsNothing);
    await tester.tap(find.text('힌트 2 보기'));
    await tester.pump();
    expect(find.text('second secret'), findsOneWidget);
    expect(find.text('third secret'), findsNothing);
    await tester.pumpWidget(view(1));
    expect(find.text('second secret'), findsOneWidget);
    await tester.tap(find.text('힌트 3 보기'));
    await tester.pump();
    expect(find.text('third secret'), findsOneWidget);
    expect(find.text('모든 힌트를 확인했습니다.'), findsOneWidget);
    await tester.pumpWidget(view(2));
    expect(find.text('second secret'), findsNothing);
    expect(find.text('third secret'), findsNothing);
  });
  testWidgets('blank hints still allow progression', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      ProgressiveHints(hints: ['', 'next', 'last']))));
    expect(find.text('제공된 힌트가 없습니다.'), findsOneWidget);
    await tester.tap(find.text('힌트 2 보기'));
    await tester.pump();
    expect(find.text('next'), findsOneWidget);
  });
}
