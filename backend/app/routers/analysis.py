# 파일 역할: AI 분석 관련 라우터 정의
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from fastapi import APIRouter

router = APIRouter(prefix="/analysis", tags=["analysis"])


# analyze_submission: analyze submission 처리 결과를 생성하거나 반환합니다.
@router.post("/{submission_id}")
def analyze_submission(submission_id: int):
    return {
        "wrong_type": "구현 실수",
        "analysis_text": "일부 테스트케이스에서는 정답이 나오지만 특정 입력에서 계산이 잘못되고 있습니다.",
        "hint1": "입력받은 두 값을 어떤 연산으로 처리하고 있는지 확인해보세요.",
        "hint2": "문제에서 요구하는 연산과 코드에서 실제 수행하는 연산이 같은지 비교해보세요.",
        "hint3": "결과를 만드는 핵심 한 줄의 연산자를 다시 확인해보세요.",
        "retry_guide": "예제 입력으로 직접 실행하면서 계산식을 점검한 뒤 다시 제출해보세요."
    }