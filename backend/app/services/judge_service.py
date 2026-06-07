import os
import subprocess
import sys
import tempfile
from dataclasses import dataclass


@dataclass
class JudgeCaseResult:
    result: str
    actual_output: str | None
    expected_output: str


def normalize_output(text: str) -> str:
    # 줄 끝 공백, 마지막 개행 차이 정도만 무시
    return "\n".join(line.rstrip() for line in text.strip().splitlines())


def run_python_code(source_code: str, input_data: str, timeout_sec: int = 2):
    with tempfile.TemporaryDirectory() as tmpdir:
        file_path = os.path.join(tmpdir, "main.py")

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(source_code)

        try:
            completed = subprocess.run(
                [sys.executable, file_path],
                input=input_data,
                text=True,
                capture_output=True,
                timeout=timeout_sec,
                cwd=tmpdir,
            )

            if completed.returncode != 0:
                return {
                    "status": "RUNTIME_ERROR",
                    "stdout": completed.stdout,
                    "stderr": completed.stderr,
                }

            return {
                "status": "OK",
                "stdout": completed.stdout,
                "stderr": completed.stderr,
            }

        except subprocess.TimeoutExpired:
            return {
                "status": "TIME_LIMIT",
                "stdout": "",
                "stderr": "Execution timed out",
            }


def judge_submission(source_code: str, test_cases):
    results = []
    passed_count = 0

    for tc in test_cases:
        exec_result = run_python_code(source_code, tc.input_data)

        if exec_result["status"] == "TIME_LIMIT":
            results.append(
                JudgeCaseResult(
                    result="TIME_LIMIT",
                    actual_output="",
                    expected_output=tc.expected_output,
                )
            )
            continue

        if exec_result["status"] == "RUNTIME_ERROR":
            results.append(
                JudgeCaseResult(
                    result="RUNTIME_ERROR",
                    actual_output=exec_result["stderr"],
                    expected_output=tc.expected_output,
                )
            )
            continue

        actual = normalize_output(exec_result["stdout"])
        expected = normalize_output(tc.expected_output)

        if actual == expected:
            passed_count += 1
            results.append(
                JudgeCaseResult(
                    result="ACCEPTED",
                    actual_output=actual,
                    expected_output=expected,
                )
            )
        else:
            results.append(
                JudgeCaseResult(
                    result="WRONG_ANSWER",
                    actual_output=actual,
                    expected_output=expected,
                )
            )

    total_count = len(test_cases)

    if all(r.result == "ACCEPTED" for r in results):
        verdict = "ACCEPTED"
    elif any(r.result == "TIME_LIMIT" for r in results):
        verdict = "TIME_LIMIT"
    elif any(r.result == "RUNTIME_ERROR" for r in results):
        verdict = "RUNTIME_ERROR"
    else:
        verdict = "WRONG_ANSWER"

    return verdict, passed_count, total_count, results