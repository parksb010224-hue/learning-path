# 제출 코드를 애플리케이션 서버와 분리된 최소 권한 컨테이너에서 실행합니다.
# 실제 CPU/메모리/네트워크 제한은 Docker 실행 측 judge_service.py에서도 적용합니다.
FROM python:3.12-slim
COPY runner.py /opt/judge/runner.py
RUN chmod 0555 /opt/judge/runner.py
USER 65534:65534
WORKDIR /tmp
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONIOENCODING=utf-8
ENTRYPOINT ["python", "-I", "-B", "/opt/judge/runner.py"]
