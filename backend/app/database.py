# 파일 역할: SQLAlchemy 엔진과 세션의 생성·종료를 관리하는 모듈
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""SQLAlchemy 연결 설정: 별도 ORM 코드가 사용하는 세션 팩토리입니다."""
import os
from pathlib import Path
from urllib.parse import quote_plus
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

# SQLAlchemy 사용 시에도 db.py와 동일한 접속 정보를 사용합니다.
# DB_URL을 지정하면 전체 연결 문자열로 덮어쓸 수 있습니다.
DATABASE_URL = os.getenv("DB_URL") or (
    f"mysql+pymysql://{quote_plus(os.getenv('DB_USER', 'root'))}:"
    f"{quote_plus(os.getenv('DB_PASSWORD', ''))}@"
    f"{os.getenv('DB_HOST', '127.0.0.1')}:{os.getenv('DB_PORT', '3306')}/"
    f"{os.getenv('DB_NAME', 'problem_list')}?charset=utf8mb4"
)
engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# get_db: get db 처리 결과를 생성하거나 반환합니다.
def get_db():
    """FastAPI 의존성 주입을 위한 세션 생성·종료 제너레이터입니다."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
