// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: analysis result
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
# models/analysis_result.py

from sqlalchemy import Column, Integer, Text, ForeignKey, TIMESTAMP
from sqlalchemy.sql import func
from database import Base

/// AnalysisResult: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class AnalysisResult(Base):
__tablename__ = "analysis_results"

id = Column(Integer, primary_key=True, index=True)

submission_id = Column(Integer, ForeignKey("submissions.id"))

summary = Column(Text)
mistake_reason = Column(Text)
complexity_analysis = Column(Text)
improvement_suggestion = Column(Text)
counter_example = Column(Text)

created_at = Column(TIMESTAMP, server_default=func.now())