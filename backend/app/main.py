# 파일 역할: FastAPI 애플리케이션 설정과 AI 분석·추천·통계 엔드포인트
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.auth import router as auth_router
from app.db import get_connection
from app.ai_service import analyze_submission, recommend_problems

from .routers.problems import router as problems_router
from .routers.submissions import router as submissions_router
import pymysql

app = FastAPI(title="Learning Path API")

app.include_router(auth_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# create_analysis: 제출 코드에 대한 AI 분석을 생성·저장합니다.
@app.post("/analysis/{submission_id}")
def create_analysis(submission_id: int):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    s.id,
                    s.problem_id,
                    s.source_code,
                    s.verdict,
                    p.title AS problem_title,
                    p.description AS problem_description
                FROM submissions s
                JOIN problems p ON s.problem_id = p.id
                WHERE s.id = %s
            """, (submission_id,))

            submission = cursor.fetchone()

            if not submission:
                raise HTTPException(status_code=404, detail="제출 기록을 찾을 수 없습니다.")

            cursor.execute("""
                SELECT *
                FROM ai_analyses
                WHERE submission_id = %s
            """, (submission_id,))

            existing_analysis = cursor.fetchone()

            if existing_analysis and existing_analysis.get("wrong_type") != "AI 분석 실패":
                return existing_analysis
            if existing_analysis:
                # Replace legacy failure placeholders only when generation succeeds.
                cursor.execute("DELETE FROM ai_analyses WHERE submission_id = %s", (submission_id,))

            try:
                result = analyze_submission(
                    problem_title=submission["problem_title"],
                    problem_description=submission["problem_description"],
                    source_code=submission["source_code"],
                    verdict=submission["verdict"]
                )
            except Exception as exc:
                raise HTTPException(status_code=503, detail="AI 분석을 생성하지 못했습니다. 잠시 후 다시 시도해주세요.") from exc
            if (not isinstance(result, dict)
                    or not isinstance(result.get("analysis_text"), str)
                    or not result["analysis_text"].strip()
                    or result.get("wrong_type") == "AI 분석 실패"):
                raise HTTPException(status_code=503, detail="AI 분석 응답을 읽지 못했습니다. 다시 시도해주세요.")

            cursor.execute("""
                INSERT INTO ai_analyses
                (
                    submission_id,
                    wrong_type,
                    analysis_text,
                    hint1,
                    hint2,
                    hint3,
                    retry_guide,
                    time_complexity,
                    improvement_suggestion,
                    counter_example
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                submission_id,
                result.get("wrong_type"),
                result.get("analysis_text"),
                result.get("hint1"),
                result.get("hint2"),
                result.get("hint3"),
                result.get("retry_guide"),
                result.get("time_complexity"),
                result.get("improvement_suggestion"),
                result.get("counter_example"),
            ))

            conn.commit()

            cursor.execute("""
                SELECT *
                FROM ai_analyses
                WHERE submission_id = %s
            """, (submission_id,))

            return cursor.fetchone()

    finally:
        conn.close()


# get_analysis: get analysis 처리 결과를 생성하거나 반환합니다.
@app.get("/analysis/{submission_id}")
def get_analysis(submission_id: int):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT *
                FROM ai_analyses
                WHERE submission_id = %s
            """, (submission_id,))

            analysis = cursor.fetchone()

            if not analysis:
                raise HTTPException(status_code=404, detail="분석 결과가 없습니다.")

            if analysis.get("wrong_type") == "AI 분석 실패":
                raise HTTPException(status_code=503, detail="이전 AI 분석이 실패했습니다. 다시 요청해주세요.")
            return analysis

    finally:
        conn.close()


# get_ai_recommendations: get ai recommendations 처리 결과를 생성하거나 반환합니다.
@app.get("/recommendations/ai/{submission_id}")
def get_ai_recommendations(submission_id: int):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT
                    s.id,
                    s.user_id,
                    s.problem_id,
                    s.verdict,
                    p.title AS problem_title
                FROM submissions s
                JOIN problems p ON s.problem_id = p.id
                WHERE s.id = %s
            """, (submission_id,))

            submission = cursor.fetchone()

            if not submission:
                raise HTTPException(status_code=404, detail="제출 기록을 찾을 수 없습니다.")

            if submission["verdict"] != "ACCEPTED":
                return []

            cursor.execute("""
                SELECT *
                FROM ai_analyses
                WHERE submission_id = %s
            """, (submission_id,))

            analysis = cursor.fetchone()

            wrong_type = "오답 원인 분석 전"

            if analysis:
                wrong_type = analysis.get("wrong_type") or "오답 원인 분석 전"

            cursor.execute("""
                SELECT 
                    p.id,
                    p.title,
                    p.difficulty,
                    p.category
                FROM problems p
                WHERE p.id != %s
                  AND p.id NOT IN (
                      SELECT s.problem_id
                      FROM submissions s
                      WHERE s.user_id = %s
                        AND s.verdict = 'ACCEPTED'
                  )
                ORDER BY p.id
            """, (
                submission["problem_id"],
                submission["user_id"],
            ))

            problem_list = cursor.fetchall()

            if not problem_list:
                return []

            try:
                ai_result = recommend_problems(
                    problem_title=submission["problem_title"],
                    wrong_type=wrong_type,
                    problem_list=problem_list
                )
                if not isinstance(ai_result, dict) or not isinstance(ai_result.get("recommendations"), list):
                    raise ValueError("Invalid recommendation response")
            except Exception as exc:
                raise HTTPException(status_code=503, detail="AI 추천을 불러오지 못했습니다. 다시 시도해주세요.") from exc

            recommended_ids = [
                item["problem_id"]
                for item in ai_result.get("recommendations", [])
            ]

            if not recommended_ids:
                return []

            placeholders = ",".join(["%s"] * len(recommended_ids))

            cursor.execute(f"""
                SELECT id, title, difficulty, category, description
                FROM problems
                WHERE id IN ({placeholders})
            """, recommended_ids)

            problems = cursor.fetchall()

            reason_map = {
                item["problem_id"]: item["reason"]
                for item in ai_result.get("recommendations", [])
            }

            for problem in problems:
                problem["reason"] = reason_map.get(problem["id"], "")

            return problems

    finally:
        conn.close()

# save_recommendation_feedback: save recommendation feedback 처리 결과를 생성하거나 반환합니다.
@app.post("/recommendations/feedback")
def save_recommendation_feedback(data: dict):
    user_id = data.get("user_id")
    submission_id = data.get("submission_id")
    recommended_problem_id = data.get("recommended_problem_id")
    feedback = data.get("feedback")

    if user_id is None or submission_id is None or recommended_problem_id is None or feedback is None:
        raise HTTPException(status_code=400, detail="필수 값이 누락되었습니다.")

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO recommendation_feedbacks
                (
                    user_id,
                    submission_id,
                    recommended_problem_id,
                    feedback
                )
                VALUES (%s, %s, %s, %s)
            """, (
                user_id,
                submission_id,
                recommended_problem_id,
                feedback,
            ))

            conn.commit()

            return {
                "message": "추천 피드백이 저장되었습니다."
            }

    finally:
        conn.close()

app.include_router(problems_router)
app.include_router(submissions_router)