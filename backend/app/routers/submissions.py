# 파일 역할: 제출 요청·테스트케이스 채점·작업 진행률·제출 이력 API
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.db import get_connection
from app.services.judge_service import evaluate_python_case

import hashlib
import json
from app.services.submission_jobs import submission_jobs, QueueFull, JobConflict

import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# SubmissionRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class SubmissionRequest(BaseModel):
    user_id: int
    problem_id: int
    source_code: str = Field(min_length=1, max_length=100000)
    language: str = "python"

# _grade_submission: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _grade_submission(req, on_progress=None):
    if req.language.lower() != "python":
        raise HTTPException(status_code=400, detail="현재는 Python만 지원합니다.")
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, output_mode FROM problems WHERE id = %s", (req.problem_id,))
            problem = cursor.fetchone()
            if not problem:
                raise HTTPException(status_code=404, detail="문제를 찾을 수 없습니다.")
            cursor.execute("""
                SELECT id, input_data, expected_output, is_sample
                FROM test_cases WHERE problem_id = %s ORDER BY id
            """, (req.problem_id,))
            test_cases = cursor.fetchall()
    finally:
        conn.close()
    if not test_cases:
        raise HTTPException(status_code=400, detail="이 문제에 채점용 테스트케이스가 없습니다.")

    if on_progress:
        on_progress('prepared', cases=test_cases)
    results = []
    for index, tc in enumerate(test_cases):
        if on_progress:
            on_progress('started', index=index)
        row = evaluate_python_case(req.source_code, tc["input_data"], tc["expected_output"], problem.get("output_mode", "exact"))
        row.update(test_case_id=tc["id"], is_sample=bool(tc["is_sample"]))
        results.append(row)
        if on_progress:
            on_progress('finished', index=index, result=row['result'])
    passed_count = sum(row["result"] == "ACCEPTED" for row in results)
    if passed_count == len(results):
        verdict = "ACCEPTED"
    elif any(row["result"] == "TIME_LIMIT_EXCEEDED" for row in results):
        verdict = "TIME_LIMIT_EXCEEDED"
    elif any(row["result"] == "RUNTIME_ERROR" for row in results):
        verdict = "RUNTIME_ERROR"
    else:
        verdict = "WRONG_ANSWER"

    if on_progress:
        on_progress('saving')
    save_conn = get_connection()
    try:
        with save_conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO submissions
                (user_id, problem_id, source_code, language, verdict, passed_count, total_count)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (req.user_id, req.problem_id, req.source_code, "python", verdict, passed_count, len(results)))
            submission_id = cursor.lastrowid
        save_conn.commit()
    except Exception as exc:
        save_conn.rollback()
        logger.exception("Failed to persist submission")
        raise HTTPException(status_code=503, detail="제출 결과를 저장하지 못했습니다. 서버의 DB 연결을 확인해주세요.") from exc
    finally:
        save_conn.close()
    # Hide private inputs and outputs even after formal submission.
    public_results = [{**row,
        "actual_output": row["actual_output"] if row["is_sample"] else None,
        "expected_output": row["expected_output"] if row["is_sample"] else None,
        "stderr": row["stderr"] if row["is_sample"] else None,
    } for row in results]
    return {"submission_id": submission_id, "verdict": verdict,
        "passed_count": passed_count, "total_count": len(results), "results": public_results}

# submit_code: submit code 처리 결과를 생성하거나 반환합니다.
@router.post("/submissions")
def submit_code(req: SubmissionRequest):
    # Preserve the synchronous endpoint for old clients and diagnostic scripts.
    return _grade_submission(req)


# ProgressSubmissionRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class ProgressSubmissionRequest(SubmissionRequest):
    request_key: str = Field(min_length=16, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")


# create_submission_job: create submission job 처리 결과를 생성하거나 반환합니다.
@router.post("/submission-jobs", status_code=202)
def create_submission_job(req: ProgressSubmissionRequest):
    if req.language.lower() != 'python':
        raise HTTPException(status_code=400, detail='현재는 Python만 지원합니다.')
    fingerprint = hashlib.sha256(json.dumps(
        [req.user_id, req.problem_id, req.source_code, req.language.lower()],
        ensure_ascii=False).encode('utf-8')).hexdigest()
    # The closure is only kept while queued/running; source is not in snapshots.
    try:
        return submission_jobs.submit(req.user_id, req.request_key, fingerprint,
                                      lambda progress: _grade_submission(req, progress))
    except QueueFull:
        raise HTTPException(status_code=503, detail='채점 대기열이 가득 찼습니다. 잠시 후 다시 시도해주세요.')
    except JobConflict:
        raise HTTPException(status_code=409, detail='같은 접수 키로 다른 코드를 제출할 수 없습니다.')


# get_submission_job: get submission job 처리 결과를 생성하거나 반환합니다.
@router.get("/submission-jobs/{job_id}")
def get_submission_job(job_id: str, user_id: int):
    progress = submission_jobs.get(job_id, user_id)
    if progress is None:
        raise HTTPException(status_code=404, detail='채점 작업을 찾을 수 없습니다. 서버가 재시작됐다면 제출 이력을 확인해주세요.')
    return progress


# get_submissions: get submissions 처리 결과를 생성하거나 반환합니다.
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
                    s.submitted_at,
                    s.submitted_at AS created_at
                FROM submissions s
                JOIN problems p ON s.problem_id = p.id
                WHERE s.user_id = %s
                ORDER BY s.submitted_at DESC
            """, (user_id,))
            return cursor.fetchall()
    finally:
        conn.close()

# ExampleRunRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class ExampleRunRequest(BaseModel):
    problem_id: int
    source_code: str = Field(min_length=1, max_length=100000)
    language: str = "python"


# run_examples: run examples 처리 결과를 생성하거나 반환합니다.
@router.post("/examples/run")
def run_examples(req: ExampleRunRequest):
    if req.language.lower() != "python":
        raise HTTPException(status_code=400, detail="현재는 Python만 지원합니다.")
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, output_mode FROM problems WHERE id = %s", (req.problem_id,))
            problem = cursor.fetchone()
            if not problem:
                raise HTTPException(status_code=404, detail="문제를 찾을 수 없습니다.")
            cursor.execute("""
                SELECT input_data, expected_output FROM test_cases
                WHERE problem_id = %s AND is_sample = 1 ORDER BY id
            """, (req.problem_id,))
            examples = cursor.fetchall()
    finally:
        conn.close()
    if not examples:
        raise HTTPException(status_code=400, detail="실행할 공개 예제가 없습니다.")
    results = []
    for index, example in enumerate(examples, 1):
        row = evaluate_python_case(req.source_code, example["input_data"], example["expected_output"], problem.get("output_mode", "exact"))
        results.append({"example_number": index, "input_data": example["input_data"], **row})
    return {"passed_count": sum(row["result"] == "ACCEPTED" for row in results),
        "total_count": len(results), "results": results}


# get_submission_code: get submission code 처리 결과를 생성하거나 반환합니다.
@router.get("/submissions/{user_id}/{submission_id}")
def get_submission_code(user_id: int, submission_id: int):
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT s.id, s.user_id, s.problem_id,
                       p.title AS problem_title, s.source_code, s.language,
                       s.verdict, s.passed_count, s.total_count,
                       s.submitted_at AS created_at
                FROM submissions s JOIN problems p ON p.id = s.problem_id
                WHERE s.id = %s AND s.user_id = %s
            """, (submission_id, user_id))
            submission = cursor.fetchone()
            if not submission:
                raise HTTPException(status_code=404, detail="제출 코드를 찾을 수 없습니다.")
            return submission
    finally:
        conn.close()
