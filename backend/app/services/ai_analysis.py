# 파일 역할: 선택적 레거시 OpenAI 코드 분석 보조 서비스
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import os
from openai import OpenAI

# 선택적으로 사용하는 레거시 OpenAI 분석 서비스입니다. 키가 없으면 호출 시 안내합니다.
# _get_client: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
def _get_client():
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        raise RuntimeError("OPENAI_API_KEY 환경변수가 필요합니다.")
    return OpenAI(api_key=key)


# analyze_code: analyze code 처리 결과를 생성하거나 반환합니다.
def analyze_code(problem, code, result):

    prompt = f"""
    문제:
    {problem}

    제출 코드:
    {code}

    채점 결과:
    {result}

    아래 형식으로 분석해주세요.

    1. 요약
    2. 왜 틀렸는지
    3. 시간복잡도 분석
    4. 개선 방향
    5. 반례
    """

    response = _get_client().chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": "당신은 알고리즘 코치입니다."},
            {"role": "user", "content": prompt}
        ]
    )

    return response.choices[0].message.content