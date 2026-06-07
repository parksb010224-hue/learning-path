from fastapi import APIRouter
from pydantic import BaseModel
from app.db import get_connection

import subprocess
import sys

router = APIRouter()

class SubmissionRequest(BaseModel):
    user_id: int
    problem_id: int
    source_code: str
    language: str = "python"

@router.post("/submissions")
def submit_code(req: SubmissionRequest):

    # 1. 테스트케이스 조회
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT id, input_data, expected_output
                FROM test_cases
                WHERE problem_id = %s
            """, (req.problem_id,))
            test_cases = cursor.fetchall()
    finally:
        conn.close()

    if len(test_cases) == 0:
        return {
            "submission_id": None,
            "verdict": "NO_TEST_CASES",
            "passed_count": 0,
            "total_count": 0,
            "results": []
        }

    # 2. 채점
    results = []
    passed_count = 0

    for tc in test_cases:
        try:
            result = subprocess.run(
                [sys.executable, "-c", req.source_code],
                input=tc["input_data"],
                text=True,
                capture_output=True,
                timeout=2
            )

            actual_output = result.stdout.strip()
            expected_output = tc["expected_output"].strip()

            if result.returncode != 0:
                judge_result = "RUNTIME_ERROR"
            elif actual_output == expected_output:
                judge_result = "ACCEPTED"
                passed_count += 1
            else:
                judge_result = "WRONG_ANSWER"

        except subprocess.TimeoutExpired:
            actual_output = ""
            expected_output = tc["expected_output"].strip()
            judge_result = "TIME_LIMIT_EXCEEDED"

        results.append({
            "test_case_id": tc["id"],
            "result": judge_result,
            "actual_output": actual_output,
            "expected_output": expected_output
        })

    if passed_count == len(test_cases):
        verdict = "ACCEPTED"
    else:
        verdict = "WRONG_ANSWER"

    # 3. 제출 결과 저장
    save_conn = get_connection()
    try:
        with save_conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO submissions
                (user_id, problem_id, source_code, language, verdict, passed_count, total_count)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                req.user_id,
                req.problem_id,
                req.source_code,
                req.language,
                verdict,
                passed_count,
                len(test_cases)
            ))

            save_conn.commit()
            submission_id = cursor.lastrowid
    finally:
        save_conn.close()

    return {
        "submission_id": submission_id,
        "verdict": verdict,
        "passed_count": passed_count,
        "total_count": len(test_cases),
        "results": results
    }

@router.get("/submissions/{user_id}")
def get_submissions(user_id: int):
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    s.id,
                    s.user_id,
                    s.problem_id,
                    p.title AS problem_title,
                    s.language,
                    s.verdict,
                    s.passed_count,
                    s.total_count,
                    s.submitted_at
                FROM submissions s
                JOIN problems p ON s.problem_id = p.id
                WHERE s.user_id = %s
                ORDER BY s.submitted_at DESC
            """, (user_id,))
            return cursor.fetchall()
    finally:
        conn.close()