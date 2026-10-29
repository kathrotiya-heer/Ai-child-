from datetime import datetime

from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Text,
)

from sqlalchemy.orm import relationship

from database import Base


# =========================================================
# PARENT USER
# =========================================================

class ParentUser(Base):
    __tablename__ = "parent_users"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    name = Column(
        String(50),
        nullable=False,
    )

    email = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
    )

    password_hash = Column(
        String(255),
        nullable=False,
    )

    pin_hash = Column(
        String(255),
        nullable=False,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    children = relationship(
        "Child",
        back_populates="parent",
        cascade="all, delete-orphan",
    )

    settings = relationship(
        "ParentSettings",
        back_populates="parent",
        uselist=False,
        cascade="all, delete-orphan",
    )


# =========================================================
# PARENT SETTINGS
# =========================================================

class ParentSettings(Base):
    __tablename__ = "parent_settings"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    parent_id = Column(
        Integer,
        ForeignKey(
            "parent_users.id",
            ondelete="CASCADE",
        ),
        unique=True,
        nullable=False,
        index=True,
    )

    screen_time_limit = Column(
        Integer,
        default=60,
        nullable=False,
    )

    parent = relationship(
        "ParentUser",
        back_populates="settings",
    )


# =========================================================
# CHILD
# =========================================================

class Child(Base):
    __tablename__ = "children"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    parent_id = Column(
        Integer,
        ForeignKey(
            "parent_users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    name = Column(
        String(50),
        nullable=False,
    )

    age = Column(
        Integer,
        nullable=False,
    )

    is_active = Column(
        Boolean,
        default=False,
        nullable=False,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    parent = relationship(
        "ParentUser",
        back_populates="children",
    )


# =========================================================
# LEARNING LESSONS
# =========================================================

class LearningLesson(Base):
    __tablename__ = "learning_lessons"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    subject = Column(
        String(50),
        nullable=False,
        index=True,
    )

    concept = Column(
        String(100),
        nullable=False,
        index=True,
    )

    title = Column(
        String(150),
        nullable=False,
    )

    description = Column(
        Text,
        nullable=False,
    )

    min_age = Column(
        Integer,
        nullable=False,
        index=True,
    )

    max_age = Column(
        Integer,
        nullable=False,
        index=True,
    )

    lesson_order = Column(
        Integer,
        default=1,
        nullable=False,
    )

    is_active = Column(
        Boolean,
        default=True,
        nullable=False,
    )

    # =====================================================
    # AI LEARNING FIELDS
    # =====================================================

    day_number = Column(
        Integer,
        unique=True,
        nullable=True,
        index=True,
    )

    category = Column(
        String(50),
        nullable=True,
        index=True,
    )

    skill = Column(
        String(100),
        nullable=True,
        index=True,
    )

    age_group = Column(
        String(20),
        nullable=True,
    )

    duration_minutes = Column(
        Integer,
        default=30,
        nullable=True,
    )

    introduction = Column(
        Text,
        nullable=True,
    )

    voice_text = Column(
        Text,
        nullable=True,
    )

    visual_ideas = Column(
        Text,
        nullable=True,
    )

    activities = Column(
        Text,
        nullable=True,
    )

    real_life_activity = Column(
        Text,
        nullable=True,
    )

    review_voice = Column(
        Text,
        nullable=True,
    )

    reward_stars = Column(
        Integer,
        default=10,
        nullable=True,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )


# =========================================================
# LEARNING PROGRESS
# =========================================================

class LearningProgress(Base):
    __tablename__ = "learning_progress"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    child_id = Column(
        Integer,
        ForeignKey(
            "children.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    subject = Column(
        String(50),
        nullable=False,
    )

    lessons_completed = Column(
        Integer,
        default=0,
        nullable=False,
    )

    stars = Column(
        Integer,
        default=0,
        nullable=False,
    )


# =========================================================
# QUIZ SCORE
# =========================================================

class QuizScore(Base):
    __tablename__ = "quiz_scores"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    child_id = Column(
        Integer,
        ForeignKey(
            "children.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    score = Column(
        Integer,
        nullable=False,
    )

    total_questions = Column(
        Integer,
        nullable=False,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )


# =========================================================
# SAFETY REQUEST
# =========================================================

class SafetyRequest(Base):
    __tablename__ = "safety_requests"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    child_id = Column(
        Integer,
        ForeignKey(
            "children.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    type = Column(
        String(50),
        nullable=False,
    )

    message = Column(
        String(1000),
        nullable=False,
    )

    status = Column(
        String(30),
        default="new",
        nullable=False,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )


# =========================================================
# PASSWORD RESET TOKEN
# =========================================================

class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    parent_id = Column(
        Integer,
        ForeignKey(
            "parent_users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    token_hash = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    expires_at = Column(
        DateTime,
        nullable=False,
    )

    used = Column(
        Boolean,
        default=False,
        nullable=False,
    )


# =========================================================
# PIN RESET TOKEN
# =========================================================

class PinResetToken(Base):
    __tablename__ = "pin_reset_tokens"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    parent_id = Column(
        Integer,
        ForeignKey(
            "parent_users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    token_hash = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    expires_at = Column(
        DateTime,
        nullable=False,
    )

    used = Column(
        Boolean,
        default=False,
        nullable=False,
    )