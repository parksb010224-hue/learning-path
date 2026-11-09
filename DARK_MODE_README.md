# 다크모드 적용

로그인 화면 또는 문제 목록 오른쪽 위 설정 버튼 → 라이트 / 다크 / 시스템 설정 따르기 선택. 기존 기본값은 라이트입니다. 저장 실패 시 안내 메시지를 표시하며 다시 선택할 수 있습니다. 웹에서는 HTTPS 또는 localhost에서 실행해주세요.

변경: main.dart, lib/theme/, settings_screen.dart, 주요 화면의 배경 및 보조 글자색, 예제 입출력 배경. 기존 로그인/API/채점 로직은 유지했습니다. 기존 flutter_secure_storage를 이용해 기기에 테마를 저장합니다.

## 로컬 검증
```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
설정에서 모드를 바꾼 뒤 뒤로가기로 로그인 화면을 확인하세요. 로그인 후 문제 목록/상세/코드 입력/채점/AI 분석/기록/통계를 확인하고 새로 실행해 테마 유지 여부를 확인하세요. 시스템 모드에서는 OS 테마 변경도 확인하세요.

이 수정 환경에는 Flutter/Dart SDK가 없어 analyze/test/실행 검증은 수행하지 못했습니다. 위젯 테스트는 테마 변경 중 설정 화면이 유지되는지 확인하도록 작성했습니다.
