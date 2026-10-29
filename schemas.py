from pydantic import BaseModel, Field, EmailStr
from datetime import datetime


# =========================================================
# CHILD
# =========================================================

class ChildCreate(BaseModel):
    name: str = Field(
        min_length=1,
        max_length=50,
    )

    age: int = Field(
        ge=5,
        le=13,
    )


class ChildResponse(BaseModel):
    id: int
    parent_id: int
    name: str
    age: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# =========================================================
# PARENT SETTINGS / PIN
# =========================================================

class ParentPinCreate(BaseModel):
    pin: str = Field(
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
    )


class ParentPinVerify(BaseModel):
    pin: str = Field(
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
    )


class ParentSettingsResponse(BaseModel):
    id: int
    parent_id: int
    screen_time_limit: int

    class Config:
        from_attributes = True


class ScreenTimeUpdate(BaseModel):
    minutes: int = Field(
        ge=0,
        le=1440,
    )


# =========================================================
# LEARNING PROGRESS
# =========================================================

class LearningProgressCreate(BaseModel):
    child_id: int

    subject: str = Field(
        min_length=1,
        max_length=50,
    )

    lessons_completed: int = Field(
        default=0,
        ge=0,
    )

    stars: int = Field(
        default=0,
        ge=0,
    )


class LearningProgressResponse(BaseModel):
    id: int
    child_id: int
    subject: str
    lessons_completed: int
    stars: int

    class Config:
        from_attributes = True


class LearningProgressUpdate(BaseModel):
    lessons_completed: int = Field(
        ge=0,
    )

    stars: int = Field(
        ge=0,
    )


# =========================================================
# LEARNING LESSON
# =========================================================

class LearningLessonResponse(BaseModel):
    id: int
    subject: str
    concept: str
    title: str
    description: str
    min_age: int
    max_age: int
    lesson_order: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# =========================================================
# QUIZ
# =========================================================

class QuizScoreCreate(BaseModel):
    child_id: int

    score: int = Field(
        ge=0,
    )

    total_questions: int = Field(
        gt=0,
    )


class QuizScoreResponse(BaseModel):
    id: int
    child_id: int
    score: int
    total_questions: int
    created_at: datetime

    class Config:
        from_attributes = True


class QuizSummaryResponse(BaseModel):
    total_quizzes: int
    total_questions: int
    total_correct: int
    average_percentage: float


# =========================================================
# AUTH - REGISTER
# =========================================================

class RegisterRequest(BaseModel):
    name: str = Field(
        min_length=2,
        max_length=50,
    )

    email: EmailStr

    password: str = Field(
        min_length=6,
        max_length=100,
    )

    pin: str = Field(
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
    )


# =========================================================
# AUTH - LOGIN
# =========================================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    parent_id: int
    name: str


# =========================================================
# AUTH - PROFILE
# =========================================================

class ParentProfileResponse(BaseModel):
    id: int
    name: str
    email: EmailStr

    class Config:
        from_attributes = True


# =========================================================
# AUTH - FORGOT PASSWORD
# =========================================================

class ForgotRequest(BaseModel):
    email: EmailStr


class ResetRequest(BaseModel):
    token: str = Field(
        min_length=1,
    )

    new_password: str = Field(
        min_length=6,
        max_length=100,
    )


# =========================================================
# AUTH - RESET PIN
# =========================================================

class ResetPinRequest(BaseModel):
    token: str = Field(
        min_length=1,
    )

    new_pin: str = Field(
        min_length=4,
        max_length=6,
        pattern=r"^\d{4,6}$",
    )


# =========================================================
# GENERAL RESPONSE
# =========================================================

class MessageResponse(BaseModel):
    message: str