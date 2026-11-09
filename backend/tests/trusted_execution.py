# 파일 역할: 채점 검증을 위한 신뢰된 기준 코드 실행 보조
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Local execution only for fixed, repository-owned regression fixtures.
Never imported by app code and never accepts API submissions.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

# run_trusted: run trusted 처리 결과를 생성하거나 반환합니다.
def run_trusted(source, input_data, timeout_sec=2):
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory)/'main.py'
        path.write_text(source)
        try:
            result = subprocess.run([sys.executable, str(path)], input=input_data,
                text=True, capture_output=True, timeout=timeout_sec, cwd=directory)
            return {'status': 'OK' if result.returncode == 0 else 'RUNTIME_ERROR',
                    'stdout': result.stdout, 'stderr': result.stderr}
        except subprocess.TimeoutExpired:
            return {'status': 'TIME_LIMIT', 'stdout': '', 'stderr': 'Execution timed out'}
