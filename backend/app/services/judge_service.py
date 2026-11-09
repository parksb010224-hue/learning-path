# 파일 역할: Docker 격리 채점 및 자원 제한과 결과 판정을 수행하는 서비스
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import json
import logging
import threading
import time
import uuid
import math
import subprocess
from dataclasses import dataclass


# JudgeCaseResult: 관련 데이터와 동작을 묶는 클래스입니다.
@dataclass
class JudgeCaseResult:
    result: str
    actual_output: str | None
    expected_output: str


# normalize_output: normalize output 처리 결과를 생성하거나 반환합니다.
def normalize_output(text: str) -> str:
    # 줄 끝 공백, 마지막 개행 차이 정도만 무시
    return "\n".join(line.rstrip() for line in text.strip().splitlines())


# No host-Python fallback: arbitrary submissions only run in the fixed image.
OUTPUT_LIMIT = 64 * 1024
SOURCE_LIMIT = 100_000
INPUT_LIMIT = 1024 * 1024
_SLOTS = threading.BoundedSemaphore(2)  # per API worker
_PENDING_CLEANUP = set()
_PENDING_LOCK = threading.Lock()
CLEANUP_TIMEOUT = 15
JUDGE_VERSION = "docker-diagnostics-1"
logger = logging.getLogger("uvicorn.error")



# SandboxUnavailable: 관련 데이터와 동작을 묶는 클래스입니다.
class SandboxUnavailable(RuntimeError):
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, message, code="JUDGE_UNAVAILABLE"):
        super().__init__(message)
        self.code = code



# _command: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _command(name):
    # PID 1 ignores default-action signals such as SIGXCPU. An init process
    # makes the Python runner an ordinary child, preserving its CPU-limit exit.
    return ["docker", "run", "--init", "--rm", "-i", "--pull=never", "--name", name,
            "--network=none", "--read-only", "--user=65534:65534",
            "--cap-drop=ALL", "--security-opt=no-new-privileges",
            "--memory=128m", "--memory-swap=128m", "--cpus=1", "--pids-limit=16",
            "--ulimit=nofile=64:64", "--ulimit=core=0:0",
            "--tmpfs=/tmp:rw,noexec,nosuid,nodev,size=8m",
            "--log-driver=none", "learning-path-judge:1"]


# _exchange: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _exchange(proc, payload, timeout):
    # Read both streams incrementally. communicate(capture_output) is unbounded.
    buffers = [bytearray(), bytearray()]
    overflow = threading.Event()
    lock = threading.Lock()
    total = 0

    # read: read 처리 결과를 생성하거나 반환합니다.
    def read(stream, target):
        nonlocal total
        try:
            while chunk := stream.read(4096):
                with lock:
                    remaining = max(0, OUTPUT_LIMIT - total)
                    target.extend(chunk[:remaining])
                    total += len(chunk)
                    if total > OUTPUT_LIMIT:
                        overflow.set()
        except (OSError, ValueError):
            pass
        finally:
            stream.close()

    # write: write 처리 결과를 생성하거나 반환합니다.
    def write():
        try:
            proc.stdin.write(payload)
            proc.stdin.close()
        except (BrokenPipeError, OSError, ValueError):
            pass

    readers = [threading.Thread(target=read, args=(stream, buf), daemon=True)
               for stream, buf in zip((proc.stdout, proc.stderr), buffers)]
    writer = threading.Thread(target=write, daemon=True)
    for thread in readers + [writer]:
        thread.start()
    deadline = time.monotonic() + timeout
    status = None
    while proc.poll() is None:
        if overflow.wait(0.01):
            status = "OUTPUT_LIMIT_EXCEEDED"
            break
        if time.monotonic() >= deadline:
            status = "TIME_LIMIT"
            break
    if status:
        proc.kill()
    proc.wait(timeout=5)
    # Container removal in caller closes pipes even when descendants are alive.
    return status, buffers, readers + [writer]


# _container_absent: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _container_absent(name):
    # An empty successful listing confirms absence; a CLI error does not.
    # --rm may have already removed the container while rm -f was in flight.
    listing = subprocess.run(
        ["docker", "container", "ls", "-a", "--filter", "name=^/" + name + "$",
         "--format", "{{.ID}}"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=5)
    return listing.returncode == 0 and not listing.stdout.strip()


# _cleanup_container: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _cleanup_container(name):
    last_error = None
    for attempt in range(2):
        try:
            removed = subprocess.run(["docker", "rm", "-f", name],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                timeout=CLEANUP_TIMEOUT)
            if removed.returncode == 0:
                return
        except (OSError, subprocess.SubprocessError) as exc:
            last_error = exc
        try:
            if _container_absent(name):
                return
        except (OSError, subprocess.SubprocessError) as exc:
            last_error = exc
        # Retry a delayed/in-progress deletion once, without sleeping.
    raise SandboxUnavailable(
        "채점 컨테이너의 삭제를 확인하지 못했습니다. Docker 상태를 확인한 후 다시 시도해주세요.",
        code="JUDGE_CLEANUP_FAILED"
    ) from last_error


# _recover_pending_cleanup: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _recover_pending_cleanup():
    with _PENDING_LOCK:
        pending = tuple(_PENDING_CLEANUP)
    for name in pending:
        _cleanup_container(name)
        with _PENDING_LOCK:
            _PENDING_CLEANUP.discard(name)


# run_python_code: Docker로 코드를 격리 실행하고 시간·메모리·출력 등 실행 제한을 적용합니다.
def run_python_code(source_code: str, input_data: str, timeout_sec: int = 2):
    if len(source_code.encode("utf-8")) > SOURCE_LIMIT or len(input_data.encode("utf-8")) > INPUT_LIMIT:
        raise SandboxUnavailable("코드 또는 입력 데이터의 허용 크기를 초과했습니다.", code="JUDGE_INPUT_SIZE")
    if not _SLOTS.acquire(blocking=False):
        raise SandboxUnavailable("채점 서버가 사용 중입니다. 잠시 후 다시 시도해주세요.", code="JUDGE_BUSY")
    name = "learning-path-" + uuid.uuid4().hex
    proc = None
    threads = []
    try:
        # Do not create more containers while a previous deletion is unconfirmed.
        _recover_pending_cleanup()
        payload = json.dumps({"source": source_code, "input": input_data}, ensure_ascii=False).encode("utf-8")
        proc = subprocess.Popen(_command(name), stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # Includes startup/transport allowance. CPU budget inside container is 2s.
        status, buffers, threads = _exchange(proc, payload, timeout_sec + 3)
    except FileNotFoundError as exc:
        raise SandboxUnavailable("실행 중인 API 서버에서 docker 명령을 찾지 못했습니다. Docker가 인식되는 터미널에서 서버를 다시 실행해주세요.",
                                 code="JUDGE_DOCKER_NOT_FOUND") from exc
    except (OSError, subprocess.SubprocessError) as exc:
        raise SandboxUnavailable("Docker 실행 또는 입출력 처리에 실패했습니다. 서버 터미널의 채점 오류를 확인해주세요.",
                                 code="JUDGE_DOCKER_EXEC") from exc
    finally:
        try:
            if proc is not None:
                if proc.poll() is None:
                    proc.kill()
                try:
                    # Killing docker client alone does not stop its container.
                    _cleanup_container(name)
                except SandboxUnavailable:
                    with _PENDING_LOCK:
                        _PENDING_CLEANUP.add(name)
                    raise
                finally:
                    proc.wait(timeout=5)
                    for thread in threads:
                        thread.join(timeout=1)
        except (OSError, subprocess.SubprocessError) as exc:
            with _PENDING_LOCK:
                _PENDING_CLEANUP.add(name)
            raise SandboxUnavailable("채점 컨테이너를 정리하지 못했습니다. Docker 상태를 확인해주세요.", code="JUDGE_CLEANUP_FAILED") from exc
        finally:
            _SLOTS.release()
    if proc.returncode in (125, 126, 127):
        raise SandboxUnavailable(f"Docker 컨테이너를 시작하지 못했습니다(종료 코드 {proc.returncode}). API 서버와 같은 터미널의 Docker 연결 및 learning-path-judge:1 이미지를 확인해주세요.", code="JUDGE_DOCKER_START")
    stdout, stderr = (bytes(buf).decode("utf-8", errors="replace") for buf in buffers)
    if status is None:
        if len(stdout.encode("utf-8")) + len(stderr.encode("utf-8")) >= OUTPUT_LIMIT:
            status = "OUTPUT_LIMIT_EXCEEDED"
        elif proc.returncode == 152:  # SIGXCPU
            status = "TIME_LIMIT"
        else:
            status = "OK" if proc.returncode == 0 else "RUNTIME_ERROR"
    return {"status": status, "stdout": stdout, "stderr": stderr,
            "exit_code": proc.returncode}



# outputs_equal: outputs equal 처리 결과를 생성하거나 반환합니다.
def outputs_equal(actual: str, expected: str, mode: str = "exact") -> bool:
    if mode != "float":
        return actual.strip() == expected.strip()
    # Numeric problems accept a single finite number, never NaN/Infinity.
    if len(actual.split()) != 1 or len(expected.split()) != 1:
        return False
    try:
        actual_number, expected_number = float(actual), float(expected)
    except ValueError:
        return False
    return (math.isfinite(actual_number) and math.isfinite(expected_number)
            and math.isclose(actual_number, expected_number, rel_tol=1e-6, abs_tol=1e-6))


# evaluate_python_case: 실행 결과를 기대 출력과 비교해 테스트케이스 판정을 반환합니다.
def evaluate_python_case(source_code, input_data, expected_output, output_mode="exact"):
    try:
        execution = run_python_code(source_code, input_data, timeout_sec=2)
    except SandboxUnavailable as exc:
        from fastapi import HTTPException
        # Log failure stage and exception chain, never source or testcase payloads.
        logger.error("Judge unavailable version=%s code=%s", JUDGE_VERSION,
                     exc.code, exc_info=True)
        raise HTTPException(status_code=503, detail=f"[{exc.code}] {exc}") from exc
    if execution["status"] == "TIME_LIMIT":
        result = "TIME_LIMIT_EXCEEDED"
    elif execution["status"] in ("RUNTIME_ERROR", "OUTPUT_LIMIT_EXCEEDED"):
        result = "RUNTIME_ERROR"
        if execution["status"] == "OUTPUT_LIMIT_EXCEEDED":
            execution["stderr"] = "출력량 제한(64 KiB)을 초과했습니다."
    else:
        result = "ACCEPTED" if outputs_equal(execution["stdout"], expected_output, output_mode) else "WRONG_ANSWER"
    return {"result": result, "actual_output": execution["stdout"],
            "expected_output": expected_output, "stderr": execution["stderr"]}


# judge_submission: judge submission 처리 결과를 생성하거나 반환합니다.
def judge_submission(source_code: str, test_cases):
    results = []
    for tc in test_cases:
        row = evaluate_python_case(source_code, tc.input_data, tc.expected_output)
        results.append(JudgeCaseResult(result=row["result"],
            actual_output=row["actual_output"], expected_output=tc.expected_output))
    passed = sum(row.result == "ACCEPTED" for row in results)
    total = len(results)
    if total and passed == total:
        verdict = "ACCEPTED"
    elif any(row.result == "TIME_LIMIT_EXCEEDED" for row in results):
        verdict = "TIME_LIMIT_EXCEEDED"
    elif any(row.result == "RUNTIME_ERROR" for row in results):
        verdict = "RUNTIME_ERROR"
    else:
        verdict = "WRONG_ANSWER"
    return verdict, passed, total, results
