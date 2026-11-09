# 파일 역할: 자동화 테스트: judge api diagnostics 기능 및 경계 조건 검증
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from contextlib import redirect_stdout

path = Path(__file__).resolve().parents[1] / 'tools/check_judge_api.py'
spec = importlib.util.spec_from_file_location('judge_api_diagnostics', path)
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)

# ApiDiagnosticTests: 관련 데이터와 동작을 묶는 클래스입니다.
class ApiDiagnosticTests(unittest.TestCase):
    # test_503_detail_is_printed_instead_of_only_status: 503 detail is printed instead of only status 동작을 검증하는 테스트입니다.
    def test_503_detail_is_printed_instead_of_only_status(self):
        error = HTTPError('http://127.0.0.1:8000/examples/run', 503, 'Unavailable', {},
            io.BytesIO(json.dumps({'detail': '[JUDGE_BUSY] busy'}).encode()))
        output = io.StringIO()
        with patch.object(diag, 'urlopen', side_effect=error) as send, redirect_stdout(output):
            self.assertFalse(diag.post_example('http://127.0.0.1:8000', 6))
        self.assertIn('[JUDGE_BUSY] busy', output.getvalue())
        request = send.call_args.args[0]
        self.assertEqual(request.full_url, 'http://127.0.0.1:8000/examples/run')
        self.assertEqual(json.loads(request.data)['source_code'], 'print(0)')

    # test_wrong_answer_http200_still_confirms_execution_pipeline: wrong answer http200 still confirms execution pipeline 동작을 검증하는 테스트입니다.
    def test_wrong_answer_http200_still_confirms_execution_pipeline(self):
        response = io.BytesIO(b'{"passed_count":0,"total_count":2,"results":[]}')
        output = io.StringIO()
        with patch.object(diag, 'urlopen', return_value=response), redirect_stdout(output):
            self.assertTrue(diag.post_example('http://127.0.0.1:8000', 6))
        self.assertIn('HTTP 200', output.getvalue())
        self.assertIn('WRONG_ANSWER', output.getvalue())
