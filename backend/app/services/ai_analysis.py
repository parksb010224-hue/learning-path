from openai import OpenAI

client = OpenAI(api_key="YOUR_API_KEY")

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

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": "당신은 알고리즘 코치입니다."},
            {"role": "user", "content": prompt}
        ]
    )

    return response.choices[0].message.content