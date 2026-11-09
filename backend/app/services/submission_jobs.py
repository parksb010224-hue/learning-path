# 파일 역할: 비동기 채점 작업 큐 및 상태 조회·사용자별 작업 보호
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Bounded, single-process job queue. Stores only public progress snapshots."""
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import logging
import secrets
import threading
import time

logger = logging.getLogger(__name__)

# QueueFull: 관련 데이터와 동작을 묶는 클래스입니다.
class QueueFull(Exception):
    pass

# JobConflict: 관련 데이터와 동작을 묶는 클래스입니다.
class JobConflict(Exception):
    pass

# SubmissionJobs: 관련 데이터와 동작을 묶는 클래스입니다.
class SubmissionJobs:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, executor=None, clock=time.monotonic):
        self._executor = executor or ThreadPoolExecutor(max_workers=1, thread_name_prefix='judge')
        self._clock = clock
        self._lock = threading.RLock()
        self._jobs = {}
        self._keys = {}
        self._slots = threading.BoundedSemaphore(4)

    # _prune: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def _prune(self):
        terminal = sorted(((key, row) for key, row in self._jobs.items()
                           if row['finished_at'] is not None and row['public']['status'] in ('COMPLETED', 'FAILED')),
                          key=lambda item: item[1]['finished_at'])
        excess = max(0, len(self._jobs) - 127)
        for index, (key, row) in enumerate(terminal):
            if self._clock() - row['finished_at'] > 1800 or index < excess:
                self._keys.pop((row['owner'], row['request_key']), None)
                del self._jobs[key]

    # submit: submit 처리 결과를 생성하거나 반환합니다.
    def submit(self, owner, request_key, fingerprint, grade):
        with self._lock:
            self._prune()
            previous = self._keys.get((owner, request_key))
            if previous:
                row = self._jobs[previous]
                if row['fingerprint'] != fingerprint:
                    raise JobConflict()
                return deepcopy(row['public'])
            if not self._slots.acquire(blocking=False):
                raise QueueFull()
            job_id = secrets.token_urlsafe(24)
            row = {'owner': owner, 'request_key': request_key, 'fingerprint': fingerprint,
                   'finished_at': None, 'public': {
                       'job_id': job_id, 'status': 'QUEUED', 'total_count': 0,
                       'completed_count': 0, 'passed_count': 0, 'cases': [],
                       'error': None, 'result': None}}
            self._jobs[job_id] = row
            self._keys[(owner, request_key)] = job_id
            try:
                self._executor.submit(self._run, job_id, grade)
            except Exception:
                del self._jobs[job_id]
                del self._keys[(owner, request_key)]
                self._slots.release()
                raise
            return deepcopy(row['public'])

    # get: get 처리 결과를 생성하거나 반환합니다.
    def get(self, job_id, owner):
        with self._lock:
            self._prune()
            row = self._jobs.get(job_id)
            if row is None or row['owner'] != owner:
                return None
            return deepcopy(row['public'])

    # _progress: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def _progress(self, job_id, event, **data):
        with self._lock:
            public = self._jobs[job_id]['public']
            if event == 'prepared':
                public['cases'] = [dict(number=i + 1, test_case_id=tc['id'],
                                        is_sample=bool(tc['is_sample']), result='PENDING')
                                   for i, tc in enumerate(data['cases'])]
                public['total_count'] = len(public['cases'])
                public['status'] = 'RUNNING'
            elif event == 'started':
                public['cases'][data['index']]['result'] = 'RUNNING'
            elif event == 'finished':
                public['cases'][data['index']]['result'] = data['result']
                public['completed_count'] += 1
                public['passed_count'] += int(data['result'] == 'ACCEPTED')
            elif event == 'saving':
                public['status'] = 'SAVING'

    # _run: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def _run(self, job_id, grade):
        try:
            result = grade(lambda event, **data: self._progress(job_id, event, **data))
            with self._lock:
                public = self._jobs[job_id]['public']
                public['result'] = result
                public['status'] = 'COMPLETED'
        except Exception as exc:
            logger.exception('Submission job failed job_id=%s', job_id)
            message = (exc.detail if isinstance(getattr(exc, 'detail', None), str)
                       and hasattr(exc, 'status_code') else '채점 처리 중 서버 오류가 발생했습니다. 서버 로그를 확인해주세요.')
            with self._lock:
                public = self._jobs[job_id]['public']
                public['status'] = 'FAILED'
                public['error'] = message
                for case in public['cases']:
                    if case['result'] == 'RUNNING':
                        case['result'] = 'JUDGE_ERROR'
        finally:
            with self._lock:
                self._jobs[job_id]['finished_at'] = self._clock()
            self._slots.release()

submission_jobs = SubmissionJobs()
