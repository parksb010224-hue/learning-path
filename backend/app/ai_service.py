# 파일 역할: Gemini 요청을 생성하고 JSON 형식으로 AI 분석·문제 추천 결과를 파싱하는 서비스
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import json
import os
import re

import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

model = genai.GenerativeModel("gemini-2.5-flash")


# extract_json: 모델 응답에서 JSON 텍스트를 추출해 파이썬 객체로 변환합니다.
def extract_json(text):
    text = text.strip()

    if text.startswith("```json"):
        text = text.replace("```json", "").replace("```", "").strip()
    elif text.startswith("```"):
        text = text.replace("```", "").strip()

    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        text = match.group(0)

    return json.loads(text)


# analyze_submission: analyze submission 처리 결과를 생성하거나 반환합니다.
def analyze_submission(problem_title, problem_description, source_code, verdict):
    prompt = f"""
너는 알고리즘 문제 풀이를 도와주는 AI 튜터야.

문제 제목:
{problem_title}

문제 설명:
{problem_description}

사용자 코드:
{source_code}

채점 결과:
{verdict}

반드시 JSON만 출력해. 설명 문장, 마크다운, 코드블록 금지.

형식:
{{
  "wrong_type": "오답 유형",
  "analysis_text": "전체 분석",
  "hint1": "첫 번째 힌트",
  "hint2": "두 번째 힌트",
  "hint3": "세 번째 힌트",
  "retry_guide": "다시 풀 때의 방향",
  "time_complexity": "시간복잡도 분석",
  "improvement_suggestion": "개선 방향",
  "counter_example": "반례"
}}
"""

    response = model.generate_content(prompt)
    text = response.text


    return extract_json(text)

# recommend_problems: 사용자 풀이 이력 기반 다음 문제 추천을 요청합니다.
def recommend_problems(problem_title, wrong_type, problem_list):
    problem_text = "\n".join([
        f"{p['id']}. {p['title']} / {p['difficulty']} / {p['category']}"
        for p in problem_list
    ])

    prompt = f"""
너는 알고리즘 학습 경로를 추천하는 AI 튜터야.

사용자가 해결한 문제:
{problem_title}

학습 분석:
{wrong_type}

아래 문제 목록 중에서 다음에 풀면 좋은 문제 2개를 추천해.

문제 목록:
{problem_text}

반드시 JSON만 출력해. 마크다운 금지.

형식:
{{
  "recommendations": [
    {{
      "problem_id": 1,
      "reason": "추천 이유"
    }},
    {{
      "problem_id": 2,
      "reason": "추천 이유"
    }}
  ]
}}
"""

    response = model.generate_content(prompt)
    text = response.text


    return extract_json(text)