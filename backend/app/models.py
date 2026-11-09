# 파일 역할: 데이터베이스 ORM 테이블 모델과 컬럼 관계 정의
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
from sqlalchemy import (
    Column, Integer, String, Text, Boolean, ForeignKey, TIMESTAMP
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .database import Base


# Problem: 관련 데이터와 동작을 묶는 클래스입니다.
class Problem(Base):
    __tablename__ = "problems"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    difficulty = Column(String(30))
    category = Column(String(50))
    description = Column(Text, nullable=False)
    input_desc = Column(Text)
    output_desc = Column(Text)
    constraints_text = Column(Text)
    sample_input = Column(Text)
    sample_output = Column(Text)
    reference_solution = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    test_cases = relationship("TestCase", back_populates="problem")


# TestCase: 관련 데이터와 동작을 묶는 클래스입니다.
class TestCase(Base):
    __tablename__ = "test_cases"

    id = Column(Integer, primary_key=True, index=True)
    problem_id = Column(Integer, ForeignKey("problems.id", ondelete="CASCADE"), nullable=False)
    input_data = Column(Text, nullable=False)
    expected_output = Column(Text, nullable=False)
    is_sample = Column(Boolean, default=False)
    case_order = Column(Integer, default=1)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    problem = relationship("Problem", back_populates="test_cases")


# Submission: 관련 데이터와 동작을 묶는 클래스입니다.
class Submission(Base):
    __tablename__ = "submissions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    problem_id = Column(Integer, ForeignKey("problems.id", ondelete="CASCADE"), nullable=False)
    source_code = Column(Text, nullable=False)
    language = Column(String(30), nullable=False, default="python")
    verdict = Column(String(30), nullable=False)
    passed_count = Column(Integer, default=0)
    total_count = Column(Integer, default=0)
    submitted_at = Column(TIMESTAMP, server_default=func.current_timestamp())


# SubmissionResult: 관련 데이터와 동작을 묶는 클래스입니다.
class SubmissionResult(Base):
    __tablename__ = "submission_results"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False)
    test_case_id = Column(Integer, ForeignKey("test_cases.id", ondelete="CASCADE"), nullable=False)
    result = Column(String(30), nullable=False)
    actual_output = Column(Text)
    expected_output = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())


# AIAnalysis: 관련 데이터와 동작을 묶는 클래스입니다.
class AIAnalysis(Base):
    __tablename__ = "ai_analyses"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(
        Integer,
        ForeignKey("submissions.id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    wrong_type = Column(String(100))
    analysis_text = Column(Text)
    hint1 = Column(Text)
    hint2 = Column(Text)
    hint3 = Column(Text)
    retry_guide = Column(Text)

    time_complexity = Column(Text)
    improvement_suggestion = Column(Text)
    counter_example = Column(Text)

    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

# Hint: 관련 데이터와 동작을 묶는 클래스입니다.
class Hint(Base):
    __tablename__ = "hints"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False)
    level = Column(Integer, nullable=False)
    hint_text = Column(Text, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())