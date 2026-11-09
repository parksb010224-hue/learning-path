# 파일 역할: 자동화 테스트: submission jobs 기능 및 경계 조건 검증
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
import hashlib
import threading
from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import logging
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from test_practice_features import handler, judge, HTTPException
from test_problem_bank import Database
from trusted_execution import run_trusted

path = Path(__file__).resolve().parents[1] / 'app/services/submission_jobs.py'
spec = importlib.util.spec_from_file_location('progress_jobs_test', path)
jobs_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jobs_module)

# ManualExecutor: 관련 데이터와 동작을 묶는 클래스입니다.
class ManualExecutor:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self): self.tasks = []
    # submit: submit 처리 결과를 생성하거나 반환합니다.
    def submit(self, fn, *args): self.tasks.append((fn, args))
    # run_next: run next 처리 결과를 생성하거나 반환합니다.
    def run_next(self):
        fn, args = self.tasks.pop(0)
        fn(*args)

# ProgressTests: 관련 데이터와 동작을 묶는 클래스입니다.
class ProgressTests(unittest.TestCase):
    # setUp: setUp 처리 결과를 생성하거나 반환합니다.
    def setUp(self):
        self.executor = ManualExecutor()
        self.now = 0
        self.jobs = jobs_module.SubmissionJobs(self.executor, clock=lambda: self.now)
        self.execution_patch = patch.object(judge, 'run_python_code', run_trusted)
        self.execution_patch.start()
        self.addCleanup(self.execution_patch.stop)

    # submit: submit 처리 결과를 생성하거나 반환합니다.
    def submit(self, grade, key='key', fingerprint='hash'):
        return self.jobs.submit(6, key, fingerprint, grade)

    # grade: grade 처리 결과를 생성하거나 반환합니다.
    def grade(self, db, evaluate=None):
        return handler('app/routers/submissions.py', '_grade_submission', db,
                       evaluate_python_case=evaluate or judge.evaluate_python_case,
                       logger=logging.getLogger('test'))

    # test_real_grader_progress_redaction_and_one_persisted_result: real grader progress redaction and one persisted result 동작을 검증하는 테스트입니다.
    def test_real_grader_progress_redaction_and_one_persisted_result(self):
        db = Database()
        snapshots = []
        # evaluate: evaluate 처리 결과를 생성하거나 반환합니다.
        def evaluate(*args):
            snapshots.append(self.jobs.get(job['job_id'], 6))
            return judge.evaluate_python_case(*args)
        req = SimpleNamespace(user_id=6, problem_id=1, language='python',
                              source_code='a,b=map(int,input().split());print(a+b)')
        grade = self.grade(db, evaluate)
        job = self.submit(lambda progress: grade(req, progress))
        self.assertEqual(job['status'], 'QUEUED')
        self.assertEqual(len(self.executor.tasks), 1)
        self.executor.run_next()
        self.assertEqual(snapshots[0]['completed_count'], 0)
        self.assertEqual([case['result'] for case in snapshots[0]['cases']], ['RUNNING','PENDING'])
        self.assertEqual(snapshots[1]['completed_count'], 1)
        self.assertEqual([case['result'] for case in snapshots[1]['cases']], ['ACCEPTED','RUNNING'])
        final = self.jobs.get(job['job_id'], 6)
        self.assertEqual((final['status'],final['completed_count'],final['passed_count']), ('COMPLETED',2,2))
        self.assertEqual(final['result']['verdict'], 'ACCEPTED')
        self.assertIsNone(final['result']['results'][1]['actual_output'])
        for snapshot in snapshots:
            self.assertNotIn('source_code', json.dumps(snapshot))
            self.assertNotIn('input_data', json.dumps(snapshot))
            self.assertNotIn('expected_output', json.dumps(snapshot))
        count = db.db.execute('SELECT COUNT(*) FROM submissions').fetchone()[0]
        self.assertEqual(count, 1)
        # Retried acceptance request returns same finished job and does not grade again.
        self.assertEqual(self.submit(lambda p: self.fail('duplicate'))['job_id'], job['job_id'])
        self.assertFalse(self.executor.tasks)

    # test_error_keeps_finished_cases_and_never_invents_a_submission_id: error keeps finished cases and never invents a submission id 동작을 검증하는 테스트입니다.
    def test_error_keeps_finished_cases_and_never_invents_a_submission_id(self):
        # grade: grade 처리 결과를 생성하거나 반환합니다.
        def grade(progress):
            progress('prepared', cases=[{'id':1,'is_sample':1,'input_data':'SECRET'},
                                        {'id':2,'is_sample':0,'expected_output':'SECRET'}])
            progress('started', index=0)
            progress('finished', index=0, result='WRONG_ANSWER')
            progress('started', index=1)
            raise HTTPException(503, '[JUDGE_BUSY] busy')
        job = self.submit(grade)
        with self.assertLogs(jobs_module.logger, level='ERROR'):
            self.executor.run_next()
        result = self.jobs.get(job['job_id'],6)
        self.assertEqual(result['status'], 'FAILED')
        self.assertEqual(result['completed_count'], 1)
        self.assertEqual([c['result'] for c in result['cases']], ['WRONG_ANSWER','JUDGE_ERROR'])
        self.assertIsNone(result['result'])
        self.assertNotIn('SECRET', json.dumps(result))

    # test_saving_is_not_completed_until_persistence_succeeds: saving is not completed until persistence succeeds 동작을 검증하는 테스트입니다.
    def test_saving_is_not_completed_until_persistence_succeeds(self):
        statuses = []
        # grade: grade 처리 결과를 생성하거나 반환합니다.
        def grade(progress):
            progress('prepared', cases=[{'id':1,'is_sample':1}])
            progress('started', index=0)
            progress('finished', index=0, result='ACCEPTED')
            progress('saving')
            statuses.append(self.jobs.get(job['job_id'],6)['status'])
            raise HTTPException(503, 'save failed')
        job = self.submit(grade)
        with self.assertLogs(jobs_module.logger, level='ERROR'): self.executor.run_next()
        self.assertEqual(statuses, ['SAVING'])
        result = self.jobs.get(job['job_id'],6)
        self.assertEqual(result['status'], 'FAILED')
        self.assertIsNone(result['result'])

    # test_queue_is_bounded_and_owner_is_checked: queue is bounded and owner is checked 동작을 검증하는 테스트입니다.
    def test_queue_is_bounded_and_owner_is_checked(self):
        for i in range(4): self.submit(lambda p: {}, key=str(i))
        with self.assertRaises(jobs_module.QueueFull): self.submit(lambda p: {}, key='fifth')
        first = self.jobs.submit(6,'0','hash', lambda p: {})
        self.assertIsNone(self.jobs.get(first['job_id'],7))
        first['cases'].append('mutated')
        self.assertEqual(self.jobs.get(first['job_id'],6)['cases'], [])
        with self.assertRaises(jobs_module.JobConflict): self.submit(lambda p: {}, key='0', fingerprint='different')
        self.executor.run_next()
        self.submit(lambda p: {}, key='fifth')

    # test_terminal_jobs_expire: terminal jobs expire 동작을 검증하는 테스트입니다.
    def test_terminal_jobs_expire(self):
        job = self.submit(lambda p: {})
        self.executor.run_next()
        self.now = 1801
        self.assertIsNone(self.jobs.get(job['job_id'],6))

    # test_create_and_lookup_routes_use_same_job_and_owner: create and lookup routes use same job and owner 동작을 검증하는 테스트입니다.
    def test_create_and_lookup_routes_use_same_job_and_owner(self):
        db = Database()
        req = SimpleNamespace(user_id=6, problem_id=1, language='python',
                              request_key='a'*32, source_code='print(3)')
        create = handler('app/routers/submissions.py','create_submission_job',db,
            submission_jobs=self.jobs, ProgressSubmissionRequest=object,
            QueueFull=jobs_module.QueueFull, JobConflict=jobs_module.JobConflict,
            hashlib=hashlib, json=json)
        a, b = create(req), create(req)
        self.assertEqual(a['job_id'], b['job_id'])
        lookup = handler('app/routers/submissions.py','get_submission_job',db, submission_jobs=self.jobs)
        self.assertEqual(lookup(a['job_id'],6)['status'],'QUEUED')
        with self.assertRaises(HTTPException) as raised: lookup(a['job_id'],7)
        self.assertEqual(raised.exception.status_code,404)

    # test_threaded_worker_exposes_progress_before_completion: threaded worker exposes progress before completion 동작을 검증하는 테스트입니다.
    def test_threaded_worker_exposes_progress_before_completion(self):
        started = threading.Event()
        release = threading.Event()
        # CapturingExecutor: 관련 데이터와 동작을 묶는 클래스입니다.
        class CapturingExecutor:
            # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
            def __init__(self, pool): self.pool = pool
            # submit: submit 처리 결과를 생성하거나 반환합니다.
            def submit(self, fn, *args):
                self.future = self.pool.submit(fn, *args)
                return self.future
        # grade: grade 처리 결과를 생성하거나 반환합니다.
        def grade(progress):
            progress('prepared', cases=[{'id':1, 'is_sample':False}])
            progress('started', index=0)
            started.set()
            if not release.wait(5): raise RuntimeError('test timed out')
            progress('finished', index=0, result='ACCEPTED')
            progress('saving')
            return {'submission_id':38}
        with ThreadPoolExecutor(max_workers=1) as pool:
            executor = CapturingExecutor(pool)
            jobs = jobs_module.SubmissionJobs(executor)
            job = jobs.submit(6, 'threaded', 'hash', grade)
            try:
                self.assertTrue(started.wait(3))
                running = jobs.get(job['job_id'],6)
                self.assertEqual(running['cases'][0]['result'], 'RUNNING')
                self.assertEqual(running['completed_count'],0)
            finally:
                release.set()
            executor.future.result(timeout=3)
            self.assertEqual(jobs.get(job['job_id'],6)['status'], 'COMPLETED')
