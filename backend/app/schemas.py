from pydantic import BaseModel


class SubmitCodeRequest(BaseModel):
    user_id: int
    problem_id: int
    source_code: str
    language: str = "python"


class TestCaseResultResponse(BaseModel):
    test_case_id: int
    result: str
    actual_output: str | None = None
    expected_output: str | None = None


class SubmitCodeResponse(BaseModel):
    submission_id: int
    verdict: str
    passed_count: int
    total_count: int
    results: list[TestCaseResultResponse]