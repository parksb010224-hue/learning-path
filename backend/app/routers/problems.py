from fastapi import APIRouter, HTTPException

from app.db import get_connection


router = APIRouter(prefix="/problems", tags=["problems"])


@router.get("")
def get_problems(user_id: int):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    p.id,
                    p.title,
                    p.difficulty,
                    p.category,
                    p.description,
                    CASE
                        WHEN EXISTS (
                            SELECT 1
                            FROM submissions s
                            WHERE s.problem_id = p.id
                              AND s.user_id = %s
                              AND s.verdict = 'ACCEPTED'
                        )
                        THEN TRUE
                        ELSE FALSE
                    END AS is_solved
                FROM problems p
                ORDER BY p.id
            """, (user_id,))

            return cursor.fetchall()

    finally:
        conn.close()


@router.get("/{problem_id}")
def get_problem(problem_id: int):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    id,
                    title,
                    difficulty,
                    category,
                    description,
                    input_desc,
                    output_desc
                FROM problems
                WHERE id = %s
            """, (problem_id,))

            problem = cursor.fetchone()

            if not problem:
                raise HTTPException(status_code=404, detail="문제를 찾을 수 없습니다.")

            cursor.execute("""
                SELECT 
                    input_data,
                    expected_output
                FROM test_cases
                WHERE problem_id = %s
                ORDER BY id
            """, (problem_id,))

            examples = cursor.fetchall()

            problem["examples"] = examples

            return problem

    finally:
        conn.close()