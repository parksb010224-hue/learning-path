# 파일 역할: 자동화 테스트: problem bank 기능 및 경계 조건 검증
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Real Python execution and SQLite-backed route-function regression tests.
The MariaDB DDL itself still needs testing against the user's MariaDB server.
"""
import ast
import inspect
import json
import logging
import math
from pathlib import Path
import re
import sqlite3
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from trusted_execution import run_trusted

from test_practice_features import handler, HTTPException, judge
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from problem_bank_reference import solve
BANK = json.loads((ROOT/'data/problem_bank.json').read_text())

# Cursor: 관련 데이터와 동작을 묶는 클래스입니다.
class Cursor:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self, db): self.cursor = db.cursor()
    # __enter__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __enter__(self): return self
    # __exit__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __exit__(self, *args): self.cursor.close()
    # execute: execute 처리 결과를 생성하거나 반환합니다.
    def execute(self, sql, args): return self.cursor.execute(sql.replace('%s','?'), args)
    # fetchone: fetchone 처리 결과를 생성하거나 반환합니다.
    def fetchone(self):
        row = self.cursor.fetchone()
        return dict(row) if row is not None else None
    # fetchall: fetchall 처리 결과를 생성하거나 반환합니다.
    def fetchall(self): return [dict(row) for row in self.cursor.fetchall()]
    # lastrowid: lastrowid 처리 결과를 생성하거나 반환합니다.
    @property
    def lastrowid(self): return self.cursor.lastrowid
# Database: 관련 데이터와 동작을 묶는 클래스입니다.
class Database:
    # __init__: 외부에 노출하지 않는 내부 처리 보조 함수입니다.
    def __init__(self):
        self.db=sqlite3.connect(':memory:'); self.db.row_factory=sqlite3.Row
        self.db.executescript('''
            CREATE TABLE problems(id INTEGER PRIMARY KEY, title TEXT, output_mode TEXT, difficulty TEXT, category TEXT, description TEXT, input_desc TEXT, output_desc TEXT, input_pattern TEXT);
            CREATE TABLE test_cases(id INTEGER PRIMARY KEY, problem_id INT, input_data TEXT, expected_output TEXT, is_sample INT);
            CREATE TABLE submissions(id INTEGER PRIMARY KEY, user_id INT, problem_id INT, source_code TEXT, language TEXT, verdict TEXT, passed_count INT, total_count INT);
        ''')
        self.db.execute("INSERT INTO problems VALUES(1,'sum','exact','Easy','구현','sum','two ints','sum','two_ints')")
        self.db.execute("INSERT INTO test_cases VALUES(1,1,'1 2','3',1)")
        self.db.execute("INSERT INTO test_cases VALUES(2,1,'0 0','0',0)")
        self.db.commit()
    # cursor: cursor 처리 결과를 생성하거나 반환합니다.
    def cursor(self): return Cursor(self.db)
    # commit: commit 처리 결과를 생성하거나 반환합니다.
    def commit(self): self.db.commit()
    # rollback: rollback 처리 결과를 생성하거나 반환합니다.
    def rollback(self): self.db.rollback()
    # close: close 처리 결과를 생성하거나 반환합니다.
    def close(self): pass

# BankTests: 관련 데이터와 동작을 묶는 클래스입니다.
class BankTests(unittest.TestCase):
    # setUp: setUp 처리 결과를 생성하거나 반환합니다.
    def setUp(self):
        # Existing tests validate trusted bank/route behavior, not isolation.
        self.execution_patch = patch.object(judge, 'run_python_code', run_trusted)
        self.execution_patch.start()
        self.addCleanup(self.execution_patch.stop)

    # test_bank_counts_and_diverse_samples: bank counts and diverse samples 동작을 검증하는 테스트입니다.
    def test_bank_counts_and_diverse_samples(self):
        self.assertEqual(len(BANK),35)
        self.assertEqual(sum(len(p['cases']) for p in BANK),381)
        for p in BANK:
            self.assertEqual(sum(c['is_sample'] for c in p['cases']),2)
            self.assertGreaterEqual(len(p['cases']),9)
            self.assertEqual(len({c['input_data'] for c in p['cases']}),len(p['cases']))

    # test_all_75_original_expected_outputs_are_preserved: all 75 original expected outputs are preserved 동작을 검증하는 테스트입니다.
    def test_all_75_original_expected_outputs_are_preserved(self):
        original = [
            ['3','30','4'], ['2','3','-7'], ['6','25','-8'], ['<','>','=='],
            ['Even','Odd','Even'], ['15','55','5050'],
            ['2 4 6 8 10 12 14 16 18','3 6 9 12 15 18 21 24 27','5 10 15 20 25 30 35 40 45'],
            ['5','40','-1'], ['1','10','-5'], ['30','2','5'],
            ['olleh','edcba','level'], ['120','6','1'], ['15','100','-2'], ['3','4','0'],
            ['YES','NO','YES'], ['1 2 3 4 5','7 8 9 10','1 3 3'],
            ['1 2 3 4','5','1 2 4'], ['YES','NO','YES'], ['5','13','0'],
            ['watermelon','elephant','abcde'], ['1','4','-1'], ['2','2','3'],
            ['3','8','1'], ['3','-1','2'], ['YES','YES','NO'],
        ]
        for problem, expected in zip(BANK[:25], original):
            self.assertEqual([row['expected_output'] for row in problem['cases'][:3]],expected,problem['title'])

    # test_legacy_and_new_known_answers: legacy and new known answers 동작을 검증하는 테스트입니다.
    def test_legacy_and_new_known_answers(self):
        known={
            'add':('1 2','3'),'subtract':('3 10','-7'),'multiply':('-2 4','-8'),
            'compare':('4 4','=='),'parity':('0','Even'),'sum_n':('100','5050'),
            'times':('2','2 4 6 8 10 12 14 16 18'),
            'maximum':('3\n-1 -5 -3','-1'),'minimum':('3\n-1 -5 -3','-5'),
            'average':('5\n10 20 30 40 50','30'),'reverse':('hello','olleh'),
            'factorial':('0','1'),'array_sum':('3\n-1 2 -3','-2'),
            'count':('5\n1 2 2 3 2\n2','3'),'palindrome':('Aa','NO'),
            'sort':('3\n3 3 1','1 3 3'),'unique':('4\n4 1 2 1','1 2 4'),
            'prime':('1','NO'),'fibonacci':('7','13'),
            'longest_word':('3\ncat elephant dog','elephant'),
            'bfs':('3 1\n1 2','-1'),'components':('3 0','3'),
            'stairs':('5','8'),'coins':('3 6\n1 3 4','2'),'brackets':('())(','NO'),
            'gcd':('48 180','12'),'binary_search':('5\n1 2 2 2 4\n2','1'),
            'josephus':('7 3','3 6 2 7 5 1 4'),
            'prefix_sum':('5 2\n1 2 3 4 5\n1 3\n2 5','6\n14'),
            'bit_count':(str(2**63-1),'63'),
            'lis':('6\n10 20 10 30 20 50','4'),
            'maze':('1 1\n1','1'),'meetings':('3\n0 10\n1 2\n2 3','2'),
            'max_subarray':('3\n-5 -2 -8','-2'),
            'stack':('6\npush 3\npush 5\ntop\nsize\npop\ntop','5\n2\n5\n3'),
        }
        self.assertEqual(len(known),35)
        for key,(text,expected) in known.items(): self.assertEqual(solve(key,text),expected,key)

    # test_all_reference_programs_in_actual_python_runner: all reference programs in actual python runner 동작을 검증하는 테스트입니다.
    def test_all_reference_programs_in_actual_python_runner(self):
        prefix='import math, bisect\nfrom collections import deque\n'+inspect.getsource(solve)+'\nimport sys\n'
        for problem in BANK:
            source=prefix+f"print(solve({problem['key']!r},sys.stdin.read()),end='')\n"
            for case in problem['cases']:
                result=judge.evaluate_python_case(source,case['input_data'],case['expected_output'],problem['output_mode'])
                self.assertEqual(result['result'],'ACCEPTED',(problem['title'],case['input_data'][:80],result))

    # test_automatic_input_patterns_consume_all_cases_without_printing_answers: automatic input patterns consume all cases without printing answers 동작을 검증하는 테스트입니다.
    def test_automatic_input_patterns_consume_all_cases_without_printing_answers(self):
        path=ROOT.parent/'lib/utils/python_input_template.dart'
        text=path.read_text().split('const patterns = <String, String>{',1)[1].split('  };',1)[0]
        patterns={key:ast.literal_eval(value) for key,value in re.findall(r"'([a-z_]+)':\s*('(?:\\.|[^'\\])*')",text)}
        for problem in BANK:
            source=patterns[problem['input_pattern']]
            self.assertFalse(any(isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id=='print' for n in ast.walk(ast.parse(source))))
            for case in problem['cases']:
                lines=iter(case['input_data'].splitlines())
                exec(source,{'input':lambda:next(lines)})
                self.assertIsNone(next(lines,None),(problem['title'],case['input_data'][:80]))

    # test_numeric_output_rules_reject_nan_and_infinity: numeric output rules reject nan and infinity 동작을 검증하는 테스트입니다.
    def test_numeric_output_rules_reject_nan_and_infinity(self):
        self.assertTrue(judge.outputs_equal('30.0','30','float'))
        self.assertTrue(judge.outputs_equal('0.6666666666666666','0.666666666667','float'))
        for value in ['nan','inf','-inf','0.66','0.6666 extra']:
            self.assertFalse(judge.outputs_equal(value,'0.666666666667','float'))
        self.assertFalse(judge.outputs_equal('30.0','30','exact'))

    # test_example_run_is_public_only_and_never_saves_a_submission: example run is public only and never saves a submission 동작을 검증하는 테스트입니다.
    def test_example_run_is_public_only_and_never_saves_a_submission(self):
        db=Database()
        run=handler('app/routers/submissions.py','run_examples',db)
        result=run(SimpleNamespace(problem_id=1,source_code='print(3)',language='python'))
        self.assertEqual(result['total_count'],1)
        self.assertEqual(result['passed_count'],1)
        self.assertEqual(db.db.execute('SELECT COUNT(*) FROM submissions').fetchone()[0],0)

    # test_problem_detail_only_exposes_public_examples_and_pattern: problem detail only exposes public examples and pattern 동작을 검증하는 테스트입니다.
    def test_problem_detail_only_exposes_public_examples_and_pattern(self):
        db=Database()
        get=handler('app/routers/problems.py','get_problem',db)
        result=get(1)
        self.assertEqual(result['input_pattern'],'two_ints')
        self.assertEqual(result['examples'],[{'input_data':'1 2','expected_output':'3'}])

    # test_formal_submission_checks_hidden_cases_and_redacts_outputs: formal submission checks hidden cases and redacts outputs 동작을 검증하는 테스트입니다.
    def test_formal_submission_checks_hidden_cases_and_redacts_outputs(self):
        db=Database()
        submit=handler('app/routers/submissions.py','submit_code',db,logger=logging.getLogger('test'))
        result=submit(SimpleNamespace(user_id=7,problem_id=1,source_code='print(3)',language='python'))
        self.assertEqual(result['verdict'],'WRONG_ANSWER')
        self.assertEqual(result['total_count'],2)
        self.assertEqual(result['passed_count'],1)
        self.assertIsInstance(result['submission_id'],int)
        self.assertEqual(db.db.execute('SELECT COUNT(*) FROM submissions').fetchone()[0],1)
        self.assertEqual(result['results'][0]['expected_output'],'3')
        hidden=result['results'][1]
        self.assertFalse(hidden['is_sample'])
        for key in ['actual_output','expected_output','stderr']:self.assertIsNone(hidden[key])
        self.assertNotIn('input_data',hidden)

    # test_correct_formal_submission_is_saved_as_accepted: correct formal submission is saved as accepted 동작을 검증하는 테스트입니다.
    def test_correct_formal_submission_is_saved_as_accepted(self):
        db=Database()
        submit=handler('app/routers/submissions.py','submit_code',db,logger=logging.getLogger('test'))
        result=submit(SimpleNamespace(user_id=7,problem_id=1,
            source_code='a,b=map(int,input().split());print(a+b)',language='python'))
        self.assertEqual(result['verdict'],'ACCEPTED')
        self.assertEqual(result['passed_count'],2)
        saved=db.db.execute('SELECT * FROM submissions').fetchone()
        self.assertEqual(saved['user_id'],7)
        self.assertEqual(saved['verdict'],'ACCEPTED')

if __name__=='__main__':unittest.main()
