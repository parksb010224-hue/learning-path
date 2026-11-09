# 파일 역할: 채점 컨테이너 동작을 확인하는 로컬 진단 스크립트
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Run actual isolation tests after building the image; no DB or AI required."""
import os
from pathlib import Path
import sys
import unittest

os.environ['RUN_DOCKER_JUDGE_TESTS'] = '1'
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tests'))
unittest.main(module='test_judge_security', defaultTest='DockerIsolationTests', verbosity=2)
