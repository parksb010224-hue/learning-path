-- 파일 역할: Learning Path 문제은행 및 스키마 점검을 위한 SQL 스크립트입니다.
-- 실행 전 대상 데이터베이스와 변경 범위를 확인하세요.
-- Read-only preflight. Select your existing database first (normally problem_list).
SELECT DATABASE() AS selected_database;
SELECT COUNT(*) AS problems_before FROM problems;
SELECT COUNT(*) AS test_cases_before FROM test_cases;
SELECT COUNT(*) AS users_before FROM users;
SELECT COUNT(*) AS submissions_before FROM submissions;
-- This must return no rows. Duplicate titles need to be resolved before seeding.
SELECT MIN(title) AS title, COUNT(*) AS duplicate_count FROM problems
GROUP BY BINARY title HAVING COUNT(*) > 1;
SELECT id, title, difficulty, category FROM problems ORDER BY id;
