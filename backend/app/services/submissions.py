from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Problem, TestCase, Submission, SubmissionResult
from ..schemas import SubmitCodeRequest, SubmitCodeResponse, TestCaseResultResponse
from ..services.judge_service import judge_submission

router = APIRouter(prefix="/submissions", tags=["submissions"])


@router.post("", response_model=SubmitCodeResponse)
def submit_code(payload: SubmitCodeRequest, db: Session = Depends(get_db)):
    if payload.language.lower() != "python":
        raise HTTPException(status_code=400, detail="현재는 Python만 지원합니다.")

    problem = db.query(Problem).filter(Problem.id == payload.problem_id).first()
    if not problem:
        raise HTTPException(status_code=404, detail="문제를 찾을 수 없습니다.")

    test_cases = (
        db.query(TestCase)
        .filter(TestCase.problem_id == payload.problem_id)
        .order_by(TestCase.case_order.asc())
        .all()
    )

    if not test_cases:
        raise HTTPException(status_code=400, detail="테스트케이스가 없습니다.")

    verdict, passed_count, total_count, judged_results = judge_submission(
        payload.source_code,
        test_cases,
    )

    submission = Submission(
        user_id=payload.user_id,
        problem_id=payload.problem_id,
        source_code=payload.source_code,
        language=payload.language,
        verdict=verdict,
        passed_count=passed_count,
        total_count=total_count,
    )
    db.add(submission)
    db.commit()
    db.refresh(submission)

    response_results = []

    for tc, jr in zip(test_cases, judged_results):
        row = SubmissionResult(
            submission_id=submission.id,
            test_case_id=tc.id,
            result=jr.result,
            actual_output=jr.actual_output,
            expected_output=jr.expected_output,
        )
        db.add(row)

        response_results.append(
            TestCaseResultResponse(
                test_case_id=tc.id,
                result=jr.result,
                actual_output=jr.actual_output,
                expected_output=jr.expected_output,
            )
        )

    db.commit()

    return SubmitCodeResponse(
        submission_id=submission.id,
        verdict=verdict,
        passed_count=passed_count,
        total_count=total_count,
        results=response_results,
    )