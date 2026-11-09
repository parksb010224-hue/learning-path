# 파일 역할: 자동화 테스트: practice features 기능 및 경계 조건 검증
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Handler unit tests with a fake DB, plus real Python example execution.
Run: python -m unittest discover -s tests -v
FastAPI/DB/AI integration is intentionally separate from these unit tests.
"""
import ast
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from trusted_execution import run_trusted

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('judge_service', ROOT / 'app/services/judge_service.py')
import sys
judge = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = judge
spec.loader.exec_module(judge)

# HTTPException: 관련 데이터와 동작을 묶는 클래스입니다.
class HTTPException(Exception):
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, status_code, detail):
        self.status_code = status_code
        self.detail = detail

# Cursor: 관련 데이터와 동작을 묶는 클래스입니다.
class Cursor:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, one=(), many=()):
        self.one = list(one)
        self.many = list(many)
        self.queries = []
    # __enter__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __enter__(self): return self
    # __exit__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __exit__(self, *args): pass
    # execute: execute 처리 결과를 생성하거나 반환합니다.
    def execute(self, sql, args): self.queries.append((sql, args))
    # fetchone: fetchone 처리 결과를 생성하거나 반환합니다.
    def fetchone(self): return self.one.pop(0)
    # fetchall: fetchall 처리 결과를 생성하거나 반환합니다.
    def fetchall(self): return self.many.pop(0)

# Connection: 관련 데이터와 동작을 묶는 클래스입니다.
class Connection:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, cursor):
        self._cursor = cursor
        self.commits = 0
        self.closed = False
    # cursor: cursor 처리 결과를 생성하거나 반환합니다.
    def cursor(self): return self._cursor
    # commit: commit 처리 결과를 생성하거나 반환합니다.
    def commit(self): self.commits += 1
    # close: close 처리 결과를 생성하거나 반환합니다.
    def close(self): self.closed = True

# handler: handler 처리 결과를 생성하거나 반환합니다.
def handler(file, name, conn, **extra):
    tree = ast.parse((ROOT / file).read_text())
    function = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == name)
    function.decorator_list = []
    ns = {'get_connection': lambda: conn, 'HTTPException': HTTPException,
          'ExampleRunRequest': object, 'SubmissionRequest': object,
          'run_python_code': judge.run_python_code,
          'evaluate_python_case': judge.evaluate_python_case, **extra}
    helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef)
               and node.name == '_grade_submission']
    exec(compile(ast.Module(body=helpers + [function], type_ignores=[]), str(file), 'exec'), ns)
    return ns[name]

# PracticeTests: 관련 데이터와 동작을 묶는 클래스입니다.
class PracticeTests(unittest.TestCase):
    # setUp: setUp 처리 결과를 생성하거나 반환합니다.
    def setUp(self):
        # Existing tests validate trusted bank/route behavior, not isolation.
        self.execution_patch = patch.object(judge, 'run_python_code', run_trusted)
        self.execution_patch.start()
        self.addCleanup(self.execution_patch.stop)

    # test_examples_run_without_creating_submissions: examples run without creating submissions 동작을 검증하는 테스트입니다.
    def test_examples_run_without_creating_submissions(self):
        cursor = Cursor(one=[{'id': 1}], many=[[
            {'input_data': '5 3\n', 'expected_output': '8\n'},
            {'input_data': '-2 1\n', 'expected_output': '-1\n'},
        ]])
        conn = Connection(cursor)
        run = handler('app/routers/submissions.py', 'run_examples', conn)
        result = run(SimpleNamespace(problem_id=1, language='python',
            source_code='a,b=map(int,input().split())\nprint(a+b)'))
        self.assertEqual(result['passed_count'], 2)
        self.assertEqual(result['total_count'], 2)
        self.assertEqual(conn.commits, 0)
        self.assertTrue(all(sql.lstrip().startswith('SELECT') for sql, _ in cursor.queries))
        self.assertTrue(conn.closed)

    # test_example_wrong_output_and_runtime_error: example wrong output and runtime error 동작을 검증하는 테스트입니다.
    def test_example_wrong_output_and_runtime_error(self):
        for code, expected in [('print(0)', 'WRONG_ANSWER'), ('1/0', 'RUNTIME_ERROR')]:
            conn = Connection(Cursor(one=[{'id': 1}], many=[[
                {'input_data': '', 'expected_output': '8'},
            ]]))
            run = handler('app/routers/submissions.py', 'run_examples', conn)
            result = run(SimpleNamespace(problem_id=1, language='python', source_code=code))
            self.assertEqual(result['results'][0]['result'], expected)
            if expected == 'RUNTIME_ERROR':
                self.assertIn('ZeroDivisionError', result['results'][0]['stderr'])

    # test_example_time_limit: example time limit 동작을 검증하는 테스트입니다.
    def test_example_time_limit(self):
        conn = Connection(Cursor(one=[{'id': 1}], many=[[
            {'input_data': '', 'expected_output': ''},
        ]]))
        run = handler('app/routers/submissions.py', 'run_examples', conn)
        result = run(SimpleNamespace(problem_id=1, language='python', source_code='while True: pass'))
        self.assertEqual(result['results'][0]['result'], 'TIME_LIMIT_EXCEEDED')

    # test_missing_problem_or_examples: missing problem or examples 동작을 검증하는 테스트입니다.
    def test_missing_problem_or_examples(self):
        for cursor, status in [(Cursor(one=[None]), 404), (Cursor(one=[{'id': 1}], many=[[]]), 400)]:
            conn = Connection(cursor)
            run = handler('app/routers/submissions.py', 'run_examples', conn)
            with self.assertRaises(HTTPException) as err:
                run(SimpleNamespace(problem_id=1, language='python', source_code='print(1)'))
            self.assertEqual(err.exception.status_code, status)
            self.assertTrue(conn.closed)

    # test_submission_lookup_is_scoped_to_user: submission lookup is scoped to user 동작을 검증하는 테스트입니다.
    def test_submission_lookup_is_scoped_to_user(self):
        cursor = Cursor(one=[{'id': 9, 'source_code': 'print(1)'}])
        conn = Connection(cursor)
        get = handler('app/routers/submissions.py', 'get_submission_code', conn)
        self.assertEqual(get(4, 9)['source_code'], 'print(1)')
        sql, args = cursor.queries[0]
        self.assertIn('s.id = %s AND s.user_id = %s', sql)
        self.assertEqual(args, (9, 4))
        self.assertTrue(conn.closed)

    # test_missing_submission_does_not_return_other_code: missing submission does not return other code 동작을 검증하는 테스트입니다.
    def test_missing_submission_does_not_return_other_code(self):
        conn = Connection(Cursor(one=[None]))
        get = handler('app/routers/submissions.py', 'get_submission_code', conn)
        with self.assertRaises(HTTPException) as err: get(4, 9)
        self.assertEqual(err.exception.status_code, 404)
        self.assertTrue(conn.closed)

    # test_ai_failure_is_retryable_and_not_saved: ai failure is retryable and not saved 동작을 검증하는 테스트입니다.
    def test_ai_failure_is_retryable_and_not_saved(self):
        cursor = Cursor(one=[{'problem_title': 'sum', 'problem_description': '',
            'source_code': 'print(1)', 'verdict': 'WRONG_ANSWER'}, None])
        conn = Connection(cursor)
        # fail: fail 처리 결과를 생성하거나 반환합니다.
        def fail(**kwargs): raise RuntimeError('AI unavailable')
        create = handler('app/main.py', 'create_analysis', conn, analyze_submission=fail)
        with self.assertRaises(HTTPException) as err: create(1)
        self.assertEqual(err.exception.status_code, 503)
        self.assertEqual(conn.commits, 0)
        self.assertFalse(any('INSERT' in sql for sql, _ in cursor.queries))
        self.assertTrue(conn.closed)

    # test_legacy_ai_failure_placeholder_is_replaced_on_success: legacy ai failure placeholder is replaced on success 동작을 검증하는 테스트입니다.
    def test_legacy_ai_failure_placeholder_is_replaced_on_success(self):
        cursor = Cursor(one=[{'problem_title': 'sum', 'problem_description': '',
            'source_code': 'print(1)', 'verdict': 'WRONG_ANSWER'},
            {'wrong_type': 'AI 분석 실패'}, {'analysis_text': 'new analysis'}])
        conn = Connection(cursor)
        create = handler('app/main.py', 'create_analysis', conn,
            analyze_submission=lambda **kwargs: {'wrong_type': 'logic', 'analysis_text': 'new analysis'})
        self.assertEqual(create(1)['analysis_text'], 'new analysis')
        self.assertTrue(any('DELETE' in sql for sql, _ in cursor.queries))
        self.assertTrue(any('INSERT' in sql for sql, _ in cursor.queries))
        self.assertEqual(conn.commits, 1)

    # test_legacy_failure_get_is_not_a_success_response: legacy failure get is not a success response 동작을 검증하는 테스트입니다.
    def test_legacy_failure_get_is_not_a_success_response(self):
        conn = Connection(Cursor(one=[{'wrong_type': 'AI 분석 실패'}]))
        get = handler('app/main.py', 'get_analysis', conn)
        with self.assertRaises(HTTPException) as err: get(1)
        self.assertEqual(err.exception.status_code, 503)

    # test_ai_recommendation_error_is_retryable: ai recommendation error is retryable 동작을 검증하는 테스트입니다.
    def test_ai_recommendation_error_is_retryable(self):
        conn = Connection(Cursor(one=[{
            'verdict': 'ACCEPTED', 'problem_id': 1, 'user_id': 4,
            'problem_title': 'sum',
        }, None], many=[[{'id': 2, 'title': 'next'}]]))
        # fail: fail 처리 결과를 생성하거나 반환합니다.
        def fail(**kwargs): raise RuntimeError('AI unavailable')
        get = handler('app/main.py', 'get_ai_recommendations', conn, recommend_problems=fail)
        with self.assertRaises(HTTPException) as err: get(1)
        self.assertEqual(err.exception.status_code, 503)
        self.assertTrue(conn.closed)

    # test_wrong_submission_never_requests_ai_recommendations: wrong submission never requests ai recommendations 동작을 검증하는 테스트입니다.
    def test_wrong_submission_never_requests_ai_recommendations(self):
        cursor = Cursor(one=[{'verdict': 'WRONG_ANSWER'}])
        conn = Connection(cursor)
        # forbidden: forbidden 처리 결과를 생성하거나 반환합니다.
        def forbidden(**kwargs): self.fail('AI recommendation was called')
        get = handler('app/main.py', 'get_ai_recommendations', conn, recommend_problems=forbidden)
        self.assertEqual(get(1), [])
        self.assertEqual(len(cursor.queries), 1)

if __name__ == '__main__': unittest.main()
