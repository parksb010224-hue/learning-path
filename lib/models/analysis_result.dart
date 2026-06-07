# models/analysis_result.py

from sqlalchemy import Column, Integer, Text, ForeignKey, TIMESTAMP
from sqlalchemy.sql import func
from database import Base

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