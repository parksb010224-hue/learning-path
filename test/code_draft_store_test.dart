// 파일 역할: Flutter 단위·위젯 테스트: code draft store test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/code_draft_store.dart';

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  test('drafts survive a new store instance and remain user/problem scoped', () async {
    final disk = <String, String>{};
    /// store: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
    CodeDraftStore store() => CodeDraftStore(
      readValue: (key) async => disk[key],
      writeValue: (key, value) async { disk[key] = value; },
    );
    final first = store();
    await first.saveDraft(1, 10, 'print(1)');
    await first.saveDraft(2, 10, 'print(2)');
    await first.saveDraft(1, 11, 'print(3)');
    final reopened = store();
    expect(await reopened.readDraft(1, 10), 'print(1)');
    expect(await reopened.readDraft(2, 10), 'print(2)');
    expect(await reopened.readDraft(1, 11), 'print(3)');
    expect(await reopened.readDraft(3, 10), isNull);
  });

  test('an intentionally empty editor stays empty on restore', () async {
    final disk = <String, String>{};
    final store = CodeDraftStore(readValue: (key) async => disk[key],
      writeValue: (key, value) async { disk[key] = value; });
    await store.saveDraft(1, 1, '');
    expect(await store.readDraft(1, 1), '');
  });

  test('retry snapshots are separate from later problem edits', () async {
    final disk = <String, String>{};
    final store = CodeDraftStore(readValue: (key) async => disk[key],
      writeValue: (key, value) async { disk[key] = value; });
    await store.saveSubmission(1, 100, 'wrong code');
    await store.saveDraft(1, 10, 'edited code');
    expect(await store.readSubmission(1, 100), 'wrong code');
    expect(await store.readSubmission(2, 100), isNull);
    expect(await store.readDraft(1, 10), 'edited code');
  });

  test('slow writes are serialized and newest edit wins', () async {
    final firstWrite = Completer<void>();
    final disk = <String, String>{};
    final started = <String>[];
    final store = CodeDraftStore(readValue: (key) async => disk[key],
      writeValue: (key, value) async {
        started.add(value);
        if (value == 'first') await firstWrite.future;
        disk[key] = value;
      });
    final first = store.saveDraft(1, 1, 'first');
    final second = store.saveDraft(1, 1, 'second');
    await Future<void>.delayed(Duration.zero);
    expect(started, ['first']);
    expect(await store.readDraft(1, 1), 'second');
    firstWrite.complete();
    await Future.wait([first, second]);
    expect(started, ['first', 'second']);
    expect(disk.values.single, 'second');
  });

  test('a failed write does not prevent subsequent saving', () async {
    var fail = true;
    final disk = <String, String>{};
    final store = CodeDraftStore(readValue: (key) async => disk[key],
      writeValue: (key, value) async {
        if (fail) throw StateError('storage unavailable');
        disk[key] = value;
      });
    await expectLater(store.saveDraft(1, 1, 'draft'), throwsStateError);
    fail = false;
    await store.saveDraft(1, 1, 'draft');
    expect(disk.values.single, 'draft');
  });

  test('a slow restore cannot overwrite a newer edit', () async {
    final read = Completer<String?>();
    final store = CodeDraftStore(readValue: (_) => read.future,
      writeValue: (_, value) async {});
    final restoring = store.readDraft(1, 1);
    await store.saveDraft(1, 1, 'new draft');
    read.complete('old draft');
    expect(await restoring, 'new draft');
  });
}
