import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('앱 실행 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const LearningPathApp());

    // 로그인 화면 확인
    expect(find.text('러닝패스 로그인'), findsOneWidget);
  });
}