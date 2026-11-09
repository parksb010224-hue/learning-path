// 파일 역할: HTTP 요청·저장소 등 앱의 외부 연동 계층: code draft store
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent local drafts are scoped by user and problem. Submission
/// snapshots have separate keys so later edits cannot alter a retry's code.
class CodeDraftStore {
  static final instance = CodeDraftStore();
  final Future<String?> Function(String key) _readValue;
  final Future<void> Function(String key, String value) _writeValue;
  final _memory = <String, String>{};
  final _pending = <String, Future<void>>{};

  CodeDraftStore({
    /// Function: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
    Future<String?> Function(String key)? readValue,
    /// Function: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
    Future<void> Function(String key, String value)? writeValue,
  }) : _readValue = readValue ?? _readSecure,
       _writeValue = writeValue ?? _writeSecure;

  static const _storage = FlutterSecureStorage();
  /// _readSecure: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  static Future<String?> _readSecure(String key) => _storage.read(key: key);
  /// _writeSecure: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  static Future<void> _writeSecure(String key, String value) =>
      _storage.write(key: key, value: value);

  /// _draftKey: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  String _draftKey(int userId, int problemId) =>
      'learning_path.code.v1.user.$userId.problem.$problemId';
  /// _submissionKey: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  String _submissionKey(int userId, int submissionId) =>
      'learning_path.code.v1.user.$userId.submission.$submissionId';

  /// readDraft: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<String?> readDraft(int userId, int problemId) =>
      _read(_draftKey(userId, problemId));
  /// saveDraft: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> saveDraft(int userId, int problemId, String code) =>
      _write(_draftKey(userId, problemId), code);
  /// readSubmission: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<String?> readSubmission(int userId, int submissionId) =>
      _read(_submissionKey(userId, submissionId));
  /// saveSubmission: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> saveSubmission(int userId, int submissionId, String code) =>
      _write(_submissionKey(userId, submissionId), code);

  /// _read: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<String?> _read(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    final value = await _readValue(key);
    // A new edit made during a slow read takes precedence.
    if (_memory.containsKey(key)) return _memory[key];
    if (value != null) _memory[key] = value;
    return value;
  }

  /// _write: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _write(String key, String value) {
    _memory[key] = value;
    final previous = _pending[key] ?? Future<void>.value();
    final operation = previous.catchError((Object _) {}).then<void>(
      (_) => _writeValue(key, value),
    );
    _pending[key] = operation;
    /// cleanup: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
    void cleanup() {
      if (identical(_pending[key], operation)) _pending.remove(key);
    }
    unawaited(operation.then<void>((_) => cleanup(),
        onError: (Object error, StackTrace stack) => cleanup()));
    return operation;
  }
}
