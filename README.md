# Learning Path

AI 기반 코딩 학습 플랫폼입니다.

## 주요 기능

- 회원가입 / 로그인
- 문제 목록 및 문제 상세 조회
- Python 코드 제출 및 테스트케이스 채점
- 제출 기록 조회
- Gemini 기반 AI 오답 분석
- AI 문제 추천
- 이미 푼 문제 추천 제외
- 추천 피드백 저장
- 학습 통계 제공

## 기술 스택

### Frontend
- Flutter
- Dart

### Backend
- FastAPI
- MariaDB
- Gemini API

## 실행 방법

### Backend

```bash
cd backend
uvicorn app.main:app --reload