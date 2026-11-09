# 파일 역할: FastAPI와 Docker 채점 경로를 점검하는 통합 진단 스크립트
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Compare local Docker execution with the running API. No submissions are saved."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app.services import judge_service as judge


# post_example: post example 처리 결과를 생성하거나 반환합니다.
def post_example(url, problem_id):
    payload = json.dumps({'problem_id': problem_id, 'source_code': 'print(0)',
                          'language': 'python'}).encode('utf-8')
    request = Request(url.rstrip('/') + '/examples/run', data=payload,
                      headers={'Content-Type': 'application/json'}, method='POST')
    try:
        with urlopen(request, timeout=120) as response:
            data = json.load(response)
        print('API: HTTP 200; execution pipeline responded; '
              'the diagnostic code print(0) may receive WRONG_ANSWER.')
        print('API passed/total:', data.get('passed_count'), '/', data.get('total_count'))
        return True
    except HTTPError as exc:
        raw = exc.read().decode('utf-8', errors='replace')
        try:
            detail = json.loads(raw).get('detail', raw)
        except (ValueError, AttributeError):
            detail = raw
        print('API HTTP:', exc.code)
        print('API detail:', detail)
    except (URLError, TimeoutError, OSError) as exc:
        print('API connection failed:', type(exc).__name__, str(exc))
    return False


# main: main 처리 결과를 생성하거나 반환합니다.
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://127.0.0.1:8000')
    parser.add_argument('--problem-id', type=int, default=6)
    args = parser.parse_args()
    print('Python:', sys.executable)
    print('Local judge file:', judge.__file__)
    print('Local judge version:', judge.JUDGE_VERSION)
    print('Docker CLI:', shutil.which('docker') or 'NOT FOUND')
    for command in (['docker','context','show'],
                    ['docker','image','inspect','--format','{{.Id}}','learning-path-judge:1']):
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=10)
            print('Docker check:', ' '.join(command[1:]), 'exit=', result.returncode)
            if result.returncode == 0:
                print(result.stdout.strip())
        except (OSError, subprocess.SubprocessError) as exc:
            print('Docker check failed:', type(exc).__name__)
    try:
        result = judge.run_python_code('print(0)', '')
        print('Local execution:', result['status'], 'exit=', result.get('exit_code'))
    except judge.SandboxUnavailable as exc:
        print('Local execution:', exc.code, str(exc))
    # Always test the API too, to expose differences from this shell/process.
    return 0 if post_example(args.url, args.problem_id) else 1


if __name__ == '__main__':
    raise SystemExit(main())
