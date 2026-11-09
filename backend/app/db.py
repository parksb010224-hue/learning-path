# 파일 역할: 환경변수 기반 PyMySQL 데이터베이스 연결 함수
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""PyMySQL 연결 설정: 서버 환경변수 또는 backend/.env에서 DB 접속 정보를 읽습니다."""
import os
from pathlib import Path
import pymysql
from dotenv import load_dotenv

# 실행 경로에 관계없이 backend/.env를 찾되, .env 파일은 Git에 포함하지 않습니다.
load_dotenv(Path(__file__).resolve().parents[1] / ".env")


# get_connection: 환경설정으로 DB 연결을 만들고 호출자에게 반환합니다.
def get_connection():
    """요청 처리에 사용할 연결을 생성합니다. 호출한 측에서 반드시 닫아야 합니다."""
    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "problem_list"),
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )
