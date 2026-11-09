# 파일 역할: 자동화 테스트: judge security 기능 및 경계 조건 검증
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import json
import signal
from pathlib import Path
import os
import subprocess
import sys
import unittest
from unittest.mock import patch
from types import SimpleNamespace
from test_practice_features import HTTPException
from test_practice_features import judge

# SecurityTests: 관련 데이터와 동작을 묶는 클래스입니다.
class SecurityTests(unittest.TestCase):
    # setUp: setUp 처리 결과를 생성하거나 반환합니다.
    def setUp(self):
        judge._PENDING_CLEANUP.clear()
        self.addCleanup(judge._PENDING_CLEANUP.clear)

    # test_fixed_restricted_command_without_host_mounts_or_env: fixed restricted command without host mounts or env 동작을 검증하는 테스트입니다.
    def test_fixed_restricted_command_without_host_mounts_or_env(self):
        cmd = judge._command('test-name')
        for option in ('--init', '--network=none', '--read-only', '--user=65534:65534',
                       '--cap-drop=ALL', '--security-opt=no-new-privileges',
                       '--memory=128m', '--memory-swap=128m', '--cpus=1',
                       '--pids-limit=16', '--pull=never', '--log-driver=none'):
            self.assertIn(option, cmd)
        self.assertNotIn('--privileged', cmd)
        self.assertFalse(any(x.startswith(('-v', '--volume', '--mount', '--env')) for x in cmd))
        self.assertEqual(cmd[-1], 'learning-path-judge:1')

    # test_missing_docker_fails_closed: missing docker fails closed 동작을 검증하는 테스트입니다.
    def test_missing_docker_fails_closed(self):
        with patch.object(judge.subprocess, 'Popen', side_effect=FileNotFoundError):
            with self.assertRaises(judge.SandboxUnavailable) as raised:
                judge.run_python_code('print(1)', '')
            self.assertEqual(raised.exception.code, 'JUDGE_DOCKER_NOT_FOUND')
        self.assertTrue(judge._SLOTS.acquire(False))
        judge._SLOTS.release()

    # test_api_failure_reports_and_logs_specific_stage_without_payload: api failure reports and logs specific stage without payload 동작을 검증하는 테스트입니다.
    def test_api_failure_reports_and_logs_specific_stage_without_payload(self):
        exc = judge.SandboxUnavailable('Docker unavailable', code='JUDGE_DOCKER_NOT_FOUND')
        with patch.object(judge, 'run_python_code', side_effect=exc), \
             patch.dict(sys.modules, {'fastapi': SimpleNamespace(HTTPException=HTTPException)}), \
             self.assertLogs('uvicorn.error', level='ERROR') as logs:
            with self.assertRaises(HTTPException) as raised:
                judge.evaluate_python_case('PRIVATE_SOURCE', 'PRIVATE_INPUT', 'PRIVATE_OUTPUT')
        self.assertEqual(raised.exception.status_code, 503)
        self.assertIn('[JUDGE_DOCKER_NOT_FOUND]', raised.exception.detail)
        output = '\n'.join(logs.output)
        self.assertIn('JUDGE_DOCKER_NOT_FOUND', output)
        for secret in ('PRIVATE_SOURCE','PRIVATE_INPUT','PRIVATE_OUTPUT'):
            self.assertNotIn(secret, output)

    # test_source_utf8_byte_limit_before_execution: source utf8 byte limit before execution 동작을 검증하는 테스트입니다.
    def test_source_utf8_byte_limit_before_execution(self):
        with patch.object(judge.subprocess, 'Popen') as start:
            with self.assertRaises(judge.SandboxUnavailable):
                judge.run_python_code('#' + '가'*40000, '')
            start.assert_not_called()

    # test_concurrency_refused_without_starting_process: concurrency refused without starting process 동작을 검증하는 테스트입니다.
    def test_concurrency_refused_without_starting_process(self):
        with patch.object(judge, '_SLOTS') as slots, patch.object(judge.subprocess, 'Popen') as start:
            slots.acquire.return_value = False
            with self.assertRaises(judge.SandboxUnavailable):
                judge.run_python_code('print(1)', '')
            start.assert_not_called()

    # exchange: exchange 처리 결과를 생성하거나 반환합니다.
    def exchange(self, code, seconds=2):
        # Trusted test producer only; exercises bounded pipe transport on host.
        proc = subprocess.Popen([sys.executable, '-c', code], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        status, buffers, threads = judge._exchange(proc, b'', seconds)
        for thread in threads: thread.join(2)
        return status, buffers

    # test_both_output_streams_are_bounded: both output streams are bounded 동작을 검증하는 테스트입니다.
    def test_both_output_streams_are_bounded(self):
        status, buffers = self.exchange("import os\nwhile True:\n os.write(1,b'x'*4096)\n os.write(2,b'y'*4096)")
        self.assertEqual(status, 'OUTPUT_LIMIT_EXCEEDED')
        self.assertLessEqual(sum(map(len,buffers)), judge.OUTPUT_LIMIT)

    # test_wall_timeout: wall timeout 동작을 검증하는 테스트입니다.
    def test_wall_timeout(self):
        status, _ = self.exchange('while True: pass', .05)
        self.assertEqual(status, 'TIME_LIMIT')

    # test_normal_transport: normal transport 동작을 검증하는 테스트입니다.
    def test_normal_transport(self):
        status, buffers = self.exchange("print('정상')")
        self.assertIsNone(status)
        self.assertEqual(bytes(buffers[0]).decode().strip(), '정상')

    # test_cleanup_on_timeout_and_no_host_fallback: cleanup on timeout and no host fallback 동작을 검증하는 테스트입니다.
    def test_cleanup_on_timeout_and_no_host_fallback(self):
        proc = unittest.mock.Mock()
        proc.poll.return_value = 0
        proc.returncode = -9
        with patch.object(judge.subprocess, 'Popen', return_value=proc), \
             patch.object(judge, '_exchange', return_value=('TIME_LIMIT',[bytearray(),bytearray()],[])), \
             patch.object(judge.subprocess, 'run', return_value=unittest.mock.Mock(returncode=0)) as cleanup:
            result = judge.run_python_code('while True: pass', '')
            self.assertEqual(result['status'], 'TIME_LIMIT')
            self.assertEqual(cleanup.call_args.args[0][:3], ['docker','rm','-f'])

    # test_cleanup_timeout_with_already_removed_container_keeps_time_limit: cleanup timeout with already removed container keeps time limit 동작을 검증하는 테스트입니다.
    def test_cleanup_timeout_with_already_removed_container_keeps_time_limit(self):
        proc = unittest.mock.Mock(returncode=-9)
        proc.poll.return_value = -9
        timeout = subprocess.TimeoutExpired(['docker', 'rm'], 15)
        absent = unittest.mock.Mock(returncode=0, stdout='')
        with patch.object(judge.subprocess, 'Popen', return_value=proc), \
             patch.object(judge, '_exchange', return_value=('TIME_LIMIT',[bytearray(),bytearray()],[])), \
             patch.object(judge.subprocess, 'run', side_effect=[timeout, absent]) as commands:
            self.assertEqual(judge.run_python_code('while True: pass', '')['status'], 'TIME_LIMIT')
            self.assertEqual(commands.call_args_list[0].kwargs['timeout'], 15)
            self.assertEqual(commands.call_args_list[1].args[0][:3], ['docker','container','ls'])

    # test_cleanup_retries_when_first_deletion_is_in_progress: cleanup retries when first deletion is in progress 동작을 검증하는 테스트입니다.
    def test_cleanup_retries_when_first_deletion_is_in_progress(self):
        with patch.object(judge.subprocess, 'run', side_effect=[
            subprocess.TimeoutExpired(['docker','rm'], 15),
            unittest.mock.Mock(returncode=0, stdout='abc123\n'),
            unittest.mock.Mock(returncode=0),
        ]) as commands:
            judge._cleanup_container('learning-path-test')
            self.assertEqual(commands.call_count, 3)

    # test_cleanup_nonzero_is_not_automatically_success: cleanup nonzero is not automatically success 동작을 검증하는 테스트입니다.
    def test_cleanup_nonzero_is_not_automatically_success(self):
        with patch.object(judge.subprocess, 'run', side_effect=[
            unittest.mock.Mock(returncode=1), unittest.mock.Mock(returncode=1, stdout=''),
            unittest.mock.Mock(returncode=1), unittest.mock.Mock(returncode=1, stdout=''),
        ]):
            with self.assertRaises(judge.SandboxUnavailable):
                judge._cleanup_container('learning-path-test')

    # test_unconfirmed_cleanup_blocks_new_execution_until_recovery: unconfirmed cleanup blocks new execution until recovery 동작을 검증하는 테스트입니다.
    def test_unconfirmed_cleanup_blocks_new_execution_until_recovery(self):
        proc = unittest.mock.Mock(returncode=-9)
        proc.poll.return_value = -9
        with patch.object(judge.subprocess, 'Popen', return_value=proc), \
             patch.object(judge, '_exchange', return_value=('TIME_LIMIT',[bytearray(),bytearray()],[])), \
             patch.object(judge, '_cleanup_container', side_effect=judge.SandboxUnavailable('cleanup failed')):
            with self.assertRaises(judge.SandboxUnavailable):
                judge.run_python_code('while True: pass', '')
        self.assertEqual(len(judge._PENDING_CLEANUP), 1)
        with patch.object(judge.subprocess, 'Popen') as start, \
             patch.object(judge, '_cleanup_container', side_effect=judge.SandboxUnavailable('still failed')):
            with self.assertRaises(judge.SandboxUnavailable):
                judge.run_python_code('print(1)', '')
            start.assert_not_called()
        with patch.object(judge, '_cleanup_container') as cleanup:
            judge._recover_pending_cleanup()
            cleanup.assert_called_once()
        self.assertFalse(judge._PENDING_CLEANUP)

    # test_real_runner_cpu_limit_as_non_pid1: real runner cpu limit as non pid1 동작을 검증하는 테스트입니다.
    @unittest.skipUnless(sys.platform == 'linux', 'Linux CPU resource limits')
    def test_real_runner_cpu_limit_as_non_pid1(self):
        # Fixed repository-owned payload only; no API/user code runs on host.
        runner = Path(__file__).resolve().parents[1] / 'sandbox/runner.py'
        completed = subprocess.run([sys.executable, '-I', str(runner)],
            input=json.dumps({'source': 'while True: pass', 'input': ''}),
            text=True, capture_output=True, timeout=6)
        self.assertEqual(completed.returncode, -signal.SIGXCPU)

    # test_cpu_signal_is_timeout_but_sigkill_is_not_assumed_timeout: cpu signal is timeout but sigkill is not assumed timeout 동작을 검증하는 테스트입니다.
    def test_cpu_signal_is_timeout_but_sigkill_is_not_assumed_timeout(self):
        # 137 is also used for OOM kills. Never label every SIGKILL as timeout.
        for exit_code, expected in ((152, 'TIME_LIMIT'), (137, 'RUNTIME_ERROR'),
                                    (1, 'RUNTIME_ERROR'), (0, 'OK')):
            with self.subTest(exit_code=exit_code):
                proc = unittest.mock.Mock(returncode=exit_code)
                proc.poll.return_value = exit_code
                with patch.object(judge.subprocess, 'Popen', return_value=proc), \
                     patch.object(judge, '_exchange', return_value=(None,[bytearray(),bytearray()],[])), \
                     patch.object(judge.subprocess, 'run', return_value=unittest.mock.Mock(returncode=0)):
                    result = judge.run_python_code('pass', '')
                    self.assertEqual(result['status'], expected)
                    self.assertEqual(result['exit_code'], exit_code)

# DockerIsolationTests: 관련 데이터와 동작을 묶는 클래스입니다.
@unittest.skipUnless(os.getenv('RUN_DOCKER_JUDGE_TESTS') == '1',
    'Requires Docker and locally built learning-path-judge:1 image')
class DockerIsolationTests(unittest.TestCase):
    # run_code: run code 처리 결과를 생성하거나 반환합니다.
    def run_code(self, source, input_data=''):
        return judge.run_python_code(source, input_data)

    # test_valid_code: valid code 동작을 검증하는 테스트입니다.
    def test_valid_code(self):
        r=self.run_code('a,b=map(int,input().split());print(a+b)', '5 3')
        self.assertEqual((r['status'],r['stdout'].strip()),('OK','8'))

    # test_server_files_and_secrets_are_absent: server files and secrets are absent 동작을 검증하는 테스트입니다.
    def test_server_files_and_secrets_are_absent(self):
        r=self.run_code("import os; print(os.getuid()); print(os.getenv('GEMINI_API_KEY')); print(os.path.exists('/var/run/docker.sock')); print(os.path.exists('/app/app/db.py'))")
        self.assertEqual(r['stdout'].splitlines(), ['65534','None','False','False'])

    # test_network_and_root_write_denied: network and root write denied 동작을 검증하는 테스트입니다.
    def test_network_and_root_write_denied(self):
        for source in ["import socket; socket.create_connection(('1.1.1.1',80),timeout=.5)",
                       "open('/forbidden','w').write('x')"]:
            self.assertEqual(self.run_code(source)['status'],'RUNTIME_ERROR')

    # test_infinite_loop_and_output: infinite loop and output 동작을 검증하는 테스트입니다.
    def test_infinite_loop_and_output(self):
        # Repeat because the old PID-1 bug depended on host/VM scheduling.
        for attempt in range(3):
            with self.subTest(attempt=attempt + 1):
                result = self.run_code('while True: pass')
                self.assertEqual(result['status'], 'TIME_LIMIT', result)
        result = self.run_code("while True: print('x'*4096)")
        self.assertEqual(result['status'], 'OUTPUT_LIMIT_EXCEEDED', result)

    # test_kernel_resource_limits: kernel resource limits 동작을 검증하는 테스트입니다.
    def test_kernel_resource_limits(self):
        source = """from pathlib import Path
import resource
import os
print(Path('/sys/fs/cgroup/memory.max').read_text().strip())
print(Path('/sys/fs/cgroup/pids.max').read_text().strip())
print(Path('/sys/fs/cgroup/cpu.max').read_text().strip())
print(resource.getrlimit(resource.RLIMIT_CPU))
print(os.getpid())
"""
        result = self.run_code(source)
        self.assertEqual(result['status'], 'OK')
        lines = result['stdout'].splitlines()
        self.assertEqual(lines[0], str(128*1024*1024))
        self.assertEqual(lines[1], '16')
        quota, period = map(int, lines[2].split())
        self.assertEqual(quota, period)
        self.assertEqual(lines[3], '(2, 3)')
        self.assertGreater(int(lines[4]), 1, 'Python must not run as container PID 1')

    # test_memory_exhaustion: memory exhaustion 동작을 검증하는 테스트입니다.
    def test_memory_exhaustion(self):
        self.assertEqual(self.run_code("x=bytearray(300*1024*1024)")['status'],'RUNTIME_ERROR')
