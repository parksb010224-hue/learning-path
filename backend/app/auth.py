# 파일 역할: 회원가입·로그인·탈퇴 API와 비밀번호 해시 검증 로직
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from passlib.context import CryptContext
import pymysql
from app.db import get_connection

router = APIRouter(prefix="/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# RegisterRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class RegisterRequest(BaseModel):
    username: str
    password: str
    nickname: str

# LoginRequest: 관련 데이터와 동작을 묶는 클래스입니다.
class LoginRequest(BaseModel):
    username: str
    password: str


# get_password_hash: get password hash 처리 결과를 생성하거나 반환합니다.
def get_password_hash(password: str):
    return pwd_context.hash(password)


# verify_password: verify password 처리 결과를 생성하거나 반환합니다.
def verify_password(plain_password: str, password_hash: str):
    return pwd_context.verify(plain_password, password_hash)

# register: 계정 중복 여부를 확인하고 안전하게 해시한 비밀번호로 사용자를 생성합니다.
@router.post("/register")
def register(request: RegisterRequest):
    conn = get_connection()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    cursor.execute(
        "SELECT id FROM users WHERE username = %s",
        (request.username,)
    )
    user = cursor.fetchone()

    if user:
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디입니다.")

    password_hash = get_password_hash(request.password)

    cursor.execute(
        """
        INSERT INTO users (username, password_hash, nickname)
        VALUES (%s, %s, %s)
        """,
        (request.username, password_hash, request.nickname)
    )

    conn.commit()
    user_id = cursor.lastrowid

    cursor.close()
    conn.close()

    return {
        "message": "회원가입 성공",
        "user_id": user_id,
        "username": request.username,
        "nickname": request.nickname
    }

# login: 아이디와 비밀번호 해시를 검증한 뒤 사용자 정보를 응답합니다.
@router.post("/login")
def login(request: LoginRequest):
    conn = get_connection()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    cursor.execute(
        """
        SELECT id, username, password_hash, nickname
        FROM users
        WHERE username = %s
        """,
        (request.username,)
    )

    user = cursor.fetchone()

    cursor.close()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 틀렸습니다.")

    if not verify_password(request.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 틀렸습니다.")

    return {
        "message": "로그인 성공",
        "user_id": user["id"],
        "username": user["username"],
        "nickname": user["nickname"]
    }

# delete_user: 요청된 사용자 계정 데이터를 제거합니다.
@router.delete("/users/{user_id}")
def delete_user(user_id: int):
    conn = get_connection()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    cursor.execute(
        "SELECT id FROM users WHERE id = %s",
        (user_id,)
    )
    user = cursor.fetchone()

    if not user:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    cursor.execute(
        "DELETE FROM users WHERE id = %s",
        (user_id,)
    )

    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "회원탈퇴 성공"}