# 검사 통과 후 API 503 진단

보안 검사 통과는 해당 Python 프로세스에서의 Docker 동작을 확인합니다. 이미 실행 중인 API 서버의 Python, PATH, Docker context, 로드한 파일 또는 당시의 컨테이너 정리 상태까지 같다는 뜻은 아닙니다. HTTP 접근 로그의 503 한 줄로는 이 중 원인을 확정할 수 없습니다. /examples/run은 예제 실행이며 정식 제출 경로는 /submissions입니다.

이번 변경은 원인을 확인하는 진단 기능입니다. 알려지지 않은 503의 원인이 해결됐다고 주장하지 않습니다. 응답 detail에 실패 단계 코드를 추가하고 서버 터미널에 예외 원인을 기록합니다. 제출 코드나 테스트 입력/출력은 로그에 넣지 않습니다.

적용:
1. 기존 백엔드를 종료합니다.
2. backend/app/services/judge_service.py와 backend/tools/check_judge_api.py를 복사합니다. 테스트 파일도 새 버전으로 교체할 수 있습니다.
3. Docker 검사가 통과한 것과 같은 Python 환경/계정에서 backend를 작업 폴더로 사용해 기존 방식으로 서버를 실행합니다. 예: python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
4. 다른 PowerShell 창에서 같은 backend 폴더로 이동한 다음 아래를 실행합니다.

```powershell
python tools/check_judge_api.py --problem-id 6
```

스크립트는 로컬 Python/파일 경로, Docker CLI/context/이미지 확인 결과, 로컬 컨테이너 실행 결과와 실제 API의 HTTP 상태/detail을 출력합니다. API에는 print(0)을 예제 실행으로 보내므로 오답이 나올 수 있으며 제출 기록은 저장하지 않습니다. 로컬 실행이 OK인데 API가 503이면 실행 중인 서버 환경/파일/상태를 확인해야 합니다. 200이면 진단 시점의 실행 경로는 정상입니다. 실패 후에는 해당 출력과 서버 터미널의 Judge unavailable 로그를 함께 확인하세요. 비밀번호나 AI 키를 출력하는 도구가 아닙니다.

| 코드 | 의미 |
|---|---|
| JUDGE_DOCKER_NOT_FOUND | API 프로세스에서 docker 명령을 찾지 못함 |
| JUDGE_DOCKER_START | 컨테이너 시작 실패 (125/126/127) |
| JUDGE_DOCKER_EXEC | 실행 명령 또는 입출력 처리 실패 |
| JUDGE_CLEANUP_FAILED | 컨테이너 삭제/프로세스 정리 확인 실패 |
| JUDGE_BUSY | 동시 실행 슬롯 사용 중 |
| JUDGE_INPUT_SIZE | 코드 또는 입력 바이트 제한 초과 |

이미지 재빌드, SQL 변경, Flutter 수정은 필요 없습니다. API 오류 표시/진단 도구 검사를 포함한 자동 검사 38개가 통과했습니다. 실제 Docker 검사 6개는 개발 환경에서 실행하지 못했으며 사용자가 별도로 통과한 결과와 구분합니다. Windows에서 API 요청까지의 실제 연동은 위 명령으로 확인해야 합니다.

---

# 컨테이너 삭제 지연 처리 수정

보고된 오류는 CPU 시간 초과 판정이 아니라 docker rm -f가 기존 제한 5초를 넘겨 발생했습니다. 이번 버전은 삭제 요청을 15초까지 기다린 뒤, 실패/시간 초과 시 컨테이너 목록을 확인합니다. Docker --rm으로 이미 자동 삭제된 경우도 정상 정리로 인정합니다. 아직 존재하거나 확인에 실패하면 삭제를 한 번 더 시도합니다. 두 번의 삭제와 확인이 모두 실패하면 기존처럼 503을 반환하고 해당 이름을 기록합니다. 이후 같은 API 프로세스에서 새 코드를 실행하기 전에 미완료 정리를 먼저 복구하므로 잔여 컨테이너를 무시하고 실행을 계속하지 않습니다.

업데이트 방법:
1. 백엔드를 종료합니다.
2. backend/app/services/judge_service.py와 backend/tests/test_judge_security.py를 교체합니다.
3. backend에서 python tools/check_judge.py를 실행합니다.
4. 통과하면 백엔드를 다시 시작합니다. Docker 이미지 재빌드와 SQL 변경은 없습니다.

삭제가 확인된 경우 시간 초과/출력 초과 판정이 유지되는지, 삭제 재시도, 이미 삭제된 컨테이너 처리, Docker 조회 실패, 정리 실패 후 새 실행 차단을 회귀 검사했습니다. Docker 없는 환경의 자동 검사 35개가 통과했고 실제 Docker 검사 6개는 사용자 PC에서 확인해야 합니다. 실제 엔진이 지속적으로 응답하지 않으면 이번 수정도 성공으로 숨기지 않고 오류를 반환합니다.

참고: https://docs.docker.com/reference/cli/docker/container/rm/

---

# CPU 시간 초과 판정 수정 안내

기존 실행 명령에는 --init이 없어 Python이 컨테이너 PID 1로 실행되었습니다. PID 1의 기본 신호 처리 특성 때문에 SIGXCPU로 끝나지 않고 하드 제한에서 종료되면, 기존 판정기는 이를 RUNTIME_ERROR로 처리했습니다. 이번 수정은 Docker --init으로 Python을 일반 자식 프로세스로 실행합니다. 메모리 초과와 혼동하지 않도록 종료 코드 137을 무조건 시간 초과로 바꾸지 않습니다.

기존 보안 버전에서 업데이트할 때:
1. 백엔드를 종료하고 새 파일을 덮어씁니다. 핵심 변경 파일은 backend/app/services/judge_service.py와 backend/tests/test_judge_security.py입니다.
2. 기존 learning-path-judge:1 이미지와 runner.py는 동일하므로 이미지 재빌드는 필요 없습니다.
3. backend 폴더에서 python tools/check_judge.py를 실행합니다. 무한 루프 검사는 내부적으로 3회 반복하고 실패 시 종료 코드도 표시합니다. 자원 제한 검사에서는 Python의 PID가 1이 아닌지도 확인합니다.
4. 검사 통과 후 백엔드를 다시 시작합니다. DB 변경은 없습니다.

Docker 공식 --init 설명: https://docs.docker.com/reference/cli/docker/container/run/#init

---

# 채점 실행 보안 강화

## 적용 방법 (Windows / Linux)

1. 기존 FastAPI 백엔드를 종료합니다.
2. Windows는 Docker Desktop을 설치·실행하고 **Linux 컨테이너** 모드를 사용합니다. Linux는 Docker Engine이 필요합니다. Docker는 FastAPI와 같은 컴퓨터에서 실행하세요. 컨테이너에 DB나 AI를 설치할 필요는 없습니다.
3. 새 프로젝트의 `backend` 폴더에서 다음을 실행합니다.

```sh
docker version
docker build --pull -t learning-path-judge:1 sandbox
python tools/check_judge.py
```

4. 실제 Docker 보안 검사 **6개가 모두 통과한 후** 기존 방식으로 FastAPI를 실행합니다. Uvicorn은 우선 `--workers 1`로 사용하세요. `--reload`는 개발 때만 사용합니다.
5. 앱에서 예제 실행과 정식 제출을 확인합니다. Flutter 변경이나 추가 DB 변경은 이번 보안 수정에 필요 없습니다. 이전 문제은행 SQL을 아직 적용하지 않았다면 FEATURES_KO.md의 DB 적용 절차를 먼저 따르세요.

최초 이미지 빌드는 인터넷이 필요합니다. 실행 때는 이미지를 자동 다운로드하지 않습니다. Docker가 꺼져 있거나 이미지가 없으면 503과 한국어 안내를 반환하고 제출 결과를 저장하지 않습니다. 서버 Python으로 우회 실행하는 옵션은 없습니다.

`check_judge.py`는 실제 컨테이너에서 정답 실행, 서버 파일·비밀값 미노출, 외부 연결·루트 쓰기 거부, 무한 루프·과다 출력 중단, 메모리 초과 중단, cgroup 제한값을 검사합니다. 이 검사는 cgroup v2 환경을 기준으로 하며, 제한값 검사에 실패하면 Docker 설정을 확인하세요. 컨테이너 이름은 learning-path-로 시작합니다.

## 적용한 제한

| 항목 | 제한 |
|---|---|
| 실행 단위 | 테스트케이스마다 새 컨테이너 |
| 사용자 | UID/GID 65534, 비관리자 |
| 네트워크 | none (외부 및 DB 연결 불가) |
| 호스트 공유 | 서버 폴더·Docker 소켓·DB 비밀번호·AI 키를 컨테이너에 전달하지 않음 |
| 파일 | 루트 읽기 전용, /tmp만 8 MiB 임시 공간, 단일 파일 1 MiB |
| CPU | 컨테이너 전체 최대 1 CPU, 프로세스 CPU 소프트 2초/하드 3초 |
| 실제 경과 시간 | 시작·입출력 포함 케이스당 5초, 초과 시 컨테이너 제거 |
| 메모리 | 컨테이너 전체 128 MiB, 추가 swap 금지 |
| 프로세스/스레드 | 컨테이너당 16개 |
| 출력 | stdout+stderr 합계 최대 64 KiB 보관, 초과 시 중단 |
| 코드/입력 | UTF-8 코드 100,000바이트, 케이스 입력 1 MiB |
| 동시 실행 | API worker당 최대 2개 컨테이너, 초과 요청은 503 |
| 권한 | Linux capabilities 모두 제거, 새 권한 취득 금지, Docker 기본 seccomp 유지 |

예제와 정식 제출 모두 동일한 제한을 사용합니다. 메모리·출력 초과는 기존 앱과 호환되도록 RUNTIME_ERROR로 표시합니다. 공개 예제의 출력 초과 stderr에는 원인을 안내합니다. 시간 초과는 TIME_LIMIT_EXCEEDED입니다. 비공개 테스트의 입력/출력/stderr는 계속 숨깁니다. 실행 후 정상·오답·오류·시간 초과 모두 컨테이너 제거를 시도합니다.

## 운영 범위와 한계

이번 수정은 제출 코드의 실행 격리입니다. Docker 컨테이너는 호스트 커널을 공유하므로 완전한 가상 머신 격리를 보장하지 않습니다. Docker와 Linux를 업데이트하고, 공개 서비스에서는 전용 채점 VM/호스트와 rootless Docker를 검토하세요. Docker 데몬 권한은 운영자만 관리하고 제출 컨테이너에 소켓을 마운트하지 마세요. API 프로세스가 갑자기 종료되거나 Docker가 응답하지 않으면 잔여 컨테이너는 운영자가 확인해야 합니다.

인증 토큰/타인 user_id 접근 방지, 사용자별 요청 횟수 제한, 여러 API worker 전체에 걸친 작업 큐는 이번 범위에 포함하지 않았습니다. 최대 2개는 프로세스별 제한이므로 worker를 늘리면 총량도 늘어납니다. 인터넷 공개 전에는 이 항목들도 별도로 보강해야 합니다.

## 검증 범위

개발 환경에서 Docker 없이 실행 가능한 출력 제한·시간 제한·동시 실행 거부·실행 옵션·정리 호출 테스트와 기존 기능 회귀 검사를 수행했습니다. 문제은행/기존 라우트 회귀 검사는 저장소의 고정된 참조 코드만 테스트 전용 로컬 실행기로 실행하며 앱에서는 이 실행기를 import하지 않습니다.

이 환경에는 Docker, MariaDB, Flutter SDK가 없어 실제 컨테이너 격리 검사는 실행하지 못했습니다. 위의 check_judge.py로 사용자 환경에서 확인해야 합니다. 실행 제한 검증 전에는 외부에 공개하지 마세요.

공식 동작 참고:
- https://docs.docker.com/engine/containers/run/
- https://docs.docker.com/reference/cli/docker/container/run/
- https://docs.docker.com/engine/security/rootless/
