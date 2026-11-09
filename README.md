# Learning Path | AI 기반 알고리즘 학습 플랫폼

> **졸업작품 프로젝트** — 문제 풀이, Docker 기반 자동 채점, AI 오답 분석과 문제 추천, 학습 통계를 한곳에서 제공하는 학습 서비스입니다.

## 주요 기능

| 영역 | 기능 |
|---|---|
| 사용자 | 회원가입, 로그인, 탈퇴 |
| 문제 풀이 | 난이도/유형 필터, 문제 상세 및 예제, 코드 임시 저장 |
| 채점 | Python 코드 실행, 공개·비공개 테스트케이스, 채점 진행 현황 표시 |
| AI 학습 지원 | Gemini 기반 오답 분석, 단계별 힌트, 후속 문제 추천 |
| 기록·분석 | 제출 기록/코드 조회, 복습 문제 목록, 유형별 학습 통계 |
| 실행 보안 | Docker 격리, 시간/자원 제한, 비공개 테스트케이스 노출 제한 |

## 기술 스택

- **Frontend:** Flutter / Dart (HTTP API)
- **Backend:** Python / FastAPI / PyMySQL
- **Database:** MySQL 호환 데이터베이스 (MySQL 또는 MariaDB)
- **AI:** Google Gemini API (`google-generativeai` 사용)
- **Judge:** Docker + Python 3.12 기반 격리 실행 이미지
- **테스트:** Python `unittest` 및 Flutter 테스트

## 구성과 데이터 흐름

```text
Flutter UI (lib/screens, lib/widgets)
       │  HTTP / JSON
       ▼
FastAPI (backend/app/main.py, app/routers)
       ├── 인증·문제·제출 ──► MySQL / MariaDB
       ├── AI 분석·추천 ────► Gemini API
       └── 채점 작업 큐 ────► Docker judge 컨테이너
                                    └── 테스트케이스별 실행·판정
```

### 폴더 구성

```text
learning_path/
├── lib/
│   ├── core/           # API 요청·클라이언트 저장소
│   ├── models/         # 모델 및 응답 파싱
│   ├── screens/        # 화면 구현
│   ├── widgets/        # 재사용 컴포넌트
│   ├── utils/          # 문제 필터와 코드 작성 도우미
│   └── theme/          # 테마 관리
├── backend/
│   ├── app/            # FastAPI·라우터·채점/AI 서비스
│   ├── sandbox/        # Docker 채점 이미지 및 러너
│   ├── data/           # 문제은행 데이터
│   ├── sql/            # DB 점검·문제은행 보강 SQL
│   ├── tools/          # 문제은행 생성 및 진단 도구
│   ├── tests/          # 서버·채점 안전성 테스트
│   └── .env.example    # 환경변수 샘플 (실제 비밀값 없음)
├── test/               # Flutter 테스트
└── README.md
```

## 로컬 실행 (개발 및 시연)

**사전 준비**: Python 3.12 권장, Flutter SDK (Dart 3.8.1 이상), Docker Desktop/Engine, MySQL 또는 MariaDB, 유효한 Gemini API 키가 필요합니다.

**1. 데이터베이스 준비**

MySQL/MariaDB에 사용할 DB와 테이블(`users`, `problems`, `test_cases`, `submissions`, `ai_analyses`, 추천 피드백 관련 테이블 등)을 준비합니다. `backend/sql/`에는 점검/문제은행 보강 SQL이 있으며, **전체 신규 DB를 자동 생성하는 설치 스크립트로 가정하면 안 됩니다.** 기존 프로젝트 DB 스키마와 순서를 확인한 뒤 적용하세요.

**2. 비밀 설정 분리**

```bash
cd backend
cp .env.example .env
```

Windows PowerShell에서는 `Copy-Item .env.example .env`를 사용합니다. `.env`에 `GEMINI_API_KEY`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`을 설정하세요. `.env`는 Git 추적 대상에서 제외됩니다.

**3. Python 의존성 및 Docker 채점 이미지**

```bash
cd backend
python -m venv .venv
# Windows PowerShell: .venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
docker build -t learning-path-judge:1 ./sandbox
```

Docker 서비스가 실행 중이어야 하고 실행 계정에 Docker 사용 권한이 필요합니다.

**4. 백엔드 시작**

```bash
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

API 문서: `http://127.0.0.1:8000/docs`.

**5. Flutter 시작**

```bash
flutter pub get
flutter run
```

## 검사 및 테스트

```bash
cd backend
python -m unittest discover -s tests
python tools/check_judge.py
python tools/check_judge_api.py
```

```bash
flutter test
flutter analyze
```

일부 테스트는 Docker 이미지, DB 설정, 실행 환경이 필요할 수 있습니다. 이 공개용 버전은 **기존 구현을 기반으로 설정·주석·문서를 정리한 것**이며, 모든 환경의 통합 실행을 보장하지 않습니다.

