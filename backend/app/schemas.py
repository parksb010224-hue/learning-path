# 파일 역할: API 입력과 출력에 사용하는 Pydantic 검증 스키마
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from pydantic import BaseModel


# SubmitCodeRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class SubmitCodeRequest(BaseModel):
    user_id: int
    problem_id: int
    source_code: str
    language: str = "python"


# TestCaseResultResponse: 관련 데이터와 동작을 묶는 클래스입니다.
class TestCaseResultResponse(BaseModel):
    test_case_id: int
    result: str
    actual_output: str | None = None
    expected_output: str | None = None


# SubmitCodeResponse: 관련 데이터와 동작을 묶는 클래스입니다.
class SubmitCodeResponse(BaseModel):
    submission_id: int
    verdict: str
    passed_count: int
    total_count: int
    results: list[TestCaseResultResponse]