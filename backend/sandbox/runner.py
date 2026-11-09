# 파일 역할: 격리 Docker 컨테이너 내부에서 제출된 Python 코드를 실행
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Runs only inside the disposable Linux container. Not a Python-level sandbox."""
import io
import json
import resource
import sys

payload = json.load(sys.stdin)
resource.setrlimit(resource.RLIMIT_CPU, (2, 3))
resource.setrlimit(resource.RLIMIT_FSIZE, (1024 * 1024, 1024 * 1024))
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
sys.stdin = io.StringIO(payload['input'])
exec(compile(payload['source'], '<submission>', 'exec'),
     {'__name__': '__main__', '__file__': '<submission>'})
