from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel

from ollama_service import generate_learning_content


import json
import ollama

from database import Base, engine, get_db
from models import Child, LearningLesson

from routers.children import router as children_router
from routers.parent import router as parent_router
from routers.learning import router as learning_router
from routers.quiz import router as quiz_router
from routers.auth import router as auth_router
from routers.admin import router as admin_router


# =========================================================
# DATABASE
# =========================================================

Base.metadata.create_all(bind=engine)


# =========================================================
# FASTAPI APP
# =========================================================

app = FastAPI(
    title="AI Child Safety & Learning API",
    description="Backend API for AI Child Safety & Learning App",
    version="1.0.0",
)

# =========================================================
# ADMIN READ-ONLY CHILD DATA
# =========================================================
# This endpoint reads the same safelearn.db used by the Flutter
# application and the normal /children API. It is intentionally
# read-only so the existing Flutter/API functionality is unchanged.
# For production, protect this endpoint with real admin authentication.

@app.get("/admin/children", include_in_schema=False)
def admin_children(db: Session = Depends(get_db)):
    children = (
        db.query(Child)
        .order_by(Child.id.desc())
        .all()
    )

    return [
        {
            "id": child.id,
            "parent_id": child.parent_id,
            "name": child.name,
            "age": child.age,
            "is_active": child.is_active,
            "created_at": child.created_at.isoformat() if child.created_at else None,
        }
        for child in children
    ]




# =========================================================
# AI LEARNING - OLLAMA
# =========================================================

# Fixed 60-day learning plan. Ollama generates the actual
# child-friendly content for each day.
LEARNING_PLAN = [
    ("At Home", "Organize My Room"),
    ("At Home", "Identify Household Objects"),
    ("At Home", "Keep My Things Safe"),
    ("At Home", "Clean Hands"),
    ("At Home", "Healthy Food Choices"),
    ("At Home", "Safe Kitchen Habits"),
    ("At Home", "Help at Home"),
    ("At Home", "Put Things in Their Place"),
    ("At Home", "Morning Routine"),
    ("At Home", "Bedtime Routine"),

    ("At School", "My School Bag"),
    ("At School", "Time Management"),
    ("At School", "Good Classroom Habits"),
    ("At School", "How to Make Simple Notes"),
    ("At School", "Sharing with Friends"),
    ("At School", "Listening Carefully"),
    ("At School", "Asking for Help"),
    ("At School", "Keeping My Desk Neat"),
    ("At School", "Following Instructions"),
    ("At School", "Being Kind at School"),

    ("At Market", "Count Money"),
    ("At Market", "Recognize Coins"),
    ("At Market", "Recognize Notes"),
    ("At Market", "Compare Prices"),
    ("At Market", "Choose What I Need"),
    ("At Market", "Calculate Simple Change"),
    ("At Market", "Make a Simple Shopping List"),
    ("At Market", "Healthy Shopping"),
    ("At Market", "Wait for My Turn"),
    ("At Market", "Safe Shopping with Parents"),

    ("Around Me", "Traffic Lights"),
    ("Around Me", "Traffic Signs"),
    ("Around Me", "Road Safety"),
    ("Around Me", "Animals Around Us"),
    ("Around Me", "Pets and Their Care"),
    ("Around Me", "Plants Around Us"),
    ("Around Me", "Parts of a Plant"),
    ("Around Me", "Weather"),
    ("Around Me", "Hot and Cold"),
    ("Around Me", "Keep My Surroundings Clean"),

    ("Life Skills", "Decision Making"),
    ("Life Skills", "Simple Problem Solving"),
    ("Life Skills", "Communication"),
    ("Life Skills", "Say Please and Thank You"),
    ("Life Skills", "Express My Feelings"),
    ("Life Skills", "Sharing and Caring"),
    ("Life Skills", "Being Responsible"),
    ("Life Skills", "Patience"),
    ("Life Skills", "Teamwork"),
    ("Life Skills", "Good Habits"),

    ("Life Skills", "Personal Safety"),
    ("Life Skills", "Trusted Adults"),
    ("Life Skills", "My Personal Information"),
    ("Life Skills", "Safe and Unsafe Situations"),
    ("Life Skills", "What to Do When Lost"),
    ("Life Skills", "Emergency Help"),
    ("Life Skills", "Digital Safety Basics"),
    ("Life Skills", "Screen Time Balance"),
    ("Life Skills", "Problem Solving at Home"),
    ("Life Skills", "Review My New Skills"),
]


def generate_learning_with_ollama(
    day_number: int,
    category: str,
    skill: str,
    age_group: str = "5-7",
):
    """Generate one learning day using the local Ollama model."""

    prompt = f"""
You are an AI educational content creator for children aged {age_group}.

Create ONE daily learning session.

Day: {day_number}
Category: {category}
Skill: {skill}

The child may not read properly. Use very simple language, visual learning,
voice-friendly sentences, interactive activities and real-life examples.
The complete session should take approximately 30 minutes.

IMPORTANT RULES:
- Return ONLY valid JSON.
- Do not return markdown.
- Do not return explanations outside JSON.
- Do not use trailing commas.
- Keep the content safe and suitable for children aged 5-7.
- Do not ask the child for private information.
- Activities must be simple enough for a young child.

Use exactly this structure:

{{
    "day": {day_number},
    "category": "{category}",
    "skill": "{skill}",
    "title": "",
    "age_group": "{age_group}",
    "duration_minutes": 30,
    "introduction": "",
    "voice_text": "",
    "visual_ideas": ["", "", ""],
    "activities": [
        {{
            "type": "tap",
            "title": "",
            "instruction": "",
            "options": ["", "", ""],
            "correct_answer": "",
            "estimated_minutes": 5
        }},
        {{
            "type": "match",
            "title": "",
            "instruction": "",
            "pairs": [
                {{"left": "", "right": ""}},
                {{"left": "", "right": ""}}
            ],
            "estimated_minutes": 5
        }},
        {{
            "type": "choose",
            "title": "",
            "instruction": "",
            "options": ["", "", ""],
            "correct_answer": "",
            "estimated_minutes": 5
        }}
    ],
    "real_life_activity": "",
    "review_voice": "",
    "reward_stars": 10
}}
"""

    response = ollama.chat(
        model="llama3.2:3b",
        format="json",
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
    )

    content = response["message"]["content"].strip()

    if content.startswith("```json"):
        content = content[7:]
    elif content.startswith("```"):
        content = content[3:]

    if content.endswith("```"):
        content = content[:-3]

    return json.loads(content.strip())


# =========================================================
# AI LEARNING - DATABASE MIGRATION
# =========================================================

def ensure_learning_columns():
    """Add new AI-learning columns to an existing SQLite table.

    This keeps the existing safelearn.db data. It does NOT delete
    or recreate the database.
    """

    from sqlalchemy import inspect, text

    inspector = inspect(engine)
    table_names = inspector.get_table_names()

    if "learning_lessons" not in table_names:
        return

    existing_columns = {
        column["name"]
        for column in inspector.get_columns("learning_lessons")
    }

    new_columns = {
        "day_number": "INTEGER",
        "category": "VARCHAR(50)",
        "skill": "VARCHAR(100)",
        "age_group": "VARCHAR(20)",
        "duration_minutes": "INTEGER",
        "introduction": "TEXT",
        "voice_text": "TEXT",
        "visual_ideas": "TEXT",
        "activities": "TEXT",
        "real_life_activity": "TEXT",
        "review_voice": "TEXT",
        "reward_stars": "INTEGER",
    }

    with engine.begin() as connection:
        for column_name, column_type in new_columns.items():
            if column_name not in existing_columns:
                connection.execute(
                    text(
                        f"ALTER TABLE learning_lessons "
                        f"ADD COLUMN {column_name} {column_type}"
                    )
                )

        # Unique index allows multiple NULLs, while preventing duplicate
        # generated day numbers.
        connection.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS "
                "ix_learning_lessons_day_number_unique "
                "ON learning_lessons(day_number)"
            )
        )


ensure_learning_columns()


# =========================================================
# AI LEARNING - GENERATE ONE DAY
# =========================================================

@app.post("/learning/generate/{day_number}")
def generate_learning_day(
    day_number: int,
    db: Session = Depends(get_db),
):
    if day_number < 1 or day_number > 60:
        raise HTTPException(
            status_code=400,
            detail="day_number must be between 1 and 60",
        )

    category, skill = LEARNING_PLAN[day_number - 1]

    existing = (
        db.query(LearningLesson)
        .filter(LearningLesson.day_number == day_number)
        .first()
    )

    if existing:
        return {
            "message": "Learning day already exists",
            "created": False,
            "day": existing.day_number,
            "title": existing.title,
            "category": existing.category,
            "skill": existing.skill,
        }

    try:
        data = generate_learning_with_ollama(
            day_number=day_number,
            category=category,
            skill=skill,
        )

        lesson = LearningLesson(
            # Existing fields - kept for compatibility
            subject=category,
            concept=skill,
            title=data["title"],
            description=data["introduction"],
            min_age=5,
            max_age=7,
            lesson_order=day_number,
            is_active=True,

            # New AI fields
            day_number=data["day"],
            category=data["category"],
            skill=data["skill"],
            age_group=data["age_group"],
            duration_minutes=data["duration_minutes"],
            introduction=data["introduction"],
            voice_text=data["voice_text"],
            visual_ideas=json.dumps(
                data.get("visual_ideas", []),
                ensure_ascii=False,
            ),
            activities=json.dumps(
                data.get("activities", []),
                ensure_ascii=False,
            ),
            real_life_activity=data.get("real_life_activity", ""),
            review_voice=data.get("review_voice", ""),
            reward_stars=data.get("reward_stars", 10),
        )

        db.add(lesson)
        db.commit()
        db.refresh(lesson)

        return {
            "message": "Learning generated and saved successfully",
            "created": True,
            "day": lesson.day_number,
            "title": lesson.title,
            "category": lesson.category,
            "skill": lesson.skill,
        }

    except json.JSONDecodeError as exc:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ollama returned invalid JSON: {exc}",
        )

    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Learning generation failed: {exc}",
        )


# =========================================================
# AI LEARNING - GET ONE DAY
# =========================================================

@app.get("/learning/day/{day_number}")
def get_learning_day(
    day_number: int,
    db: Session = Depends(get_db),
):
    lesson = (
        db.query(LearningLesson)
        .filter(
            LearningLesson.day_number == day_number,
            LearningLesson.is_active == True,
        )
        .first()
    )

    if lesson is None:
        raise HTTPException(
            status_code=404,
            detail="Learning day not generated yet",
        )

    return {
        "id": lesson.id,
        "day": lesson.day_number,
        "category": lesson.category,
        "skill": lesson.skill,
        "title": lesson.title,
        "age_group": lesson.age_group,
        "duration_minutes": lesson.duration_minutes,
        "introduction": lesson.introduction,
        "voice_text": lesson.voice_text,
        "visual_ideas": json.loads(lesson.visual_ideas or "[]"),
        "activities": json.loads(lesson.activities or "[]"),
        "real_life_activity": lesson.real_life_activity,
        "review_voice": lesson.review_voice,
        "reward_stars": lesson.reward_stars,
    }


# =========================================================
# AI LEARNING - GET ALL GENERATED DAYS
# =========================================================

@app.get("/learning/days")
def get_all_learning_days(
    db: Session = Depends(get_db),
):
    lessons = (
        db.query(LearningLesson)
        .filter(LearningLesson.day_number.isnot(None))
        .order_by(LearningLesson.day_number.asc())
        .all()
    )

    return [
        {
            "id": lesson.id,
            "day": lesson.day_number,
            "category": lesson.category,
            "skill": lesson.skill,
            "title": lesson.title,
            "duration_minutes": lesson.duration_minutes,
            "is_active": lesson.is_active,
        }
        for lesson in lessons
    ]


# =========================================================
# AI LEARNING - GENERATE ALL 60 DAYS
# =========================================================

@app.post("/learning/generate-all")
def generate_all_learning_days(
    db: Session = Depends(get_db),
):
    generated = []
    skipped = []
    failed = []

    for day_number in range(1, 61):
        category, skill = LEARNING_PLAN[day_number - 1]

        existing = (
            db.query(LearningLesson)
            .filter(LearningLesson.day_number == day_number)
            .first()
        )

        if existing:
            skipped.append(day_number)
            continue

        try:
            data = generate_learning_with_ollama(
                day_number=day_number,
                category=category,
                skill=skill,
            )

            lesson = LearningLesson(
                subject=category,
                concept=skill,
                title=data["title"],
                description=data["introduction"],
                min_age=5,
                max_age=7,
                lesson_order=day_number,
                is_active=True,
                day_number=data["day"],
                category=data["category"],
                skill=data["skill"],
                age_group=data["age_group"],
                duration_minutes=data["duration_minutes"],
                introduction=data["introduction"],
                voice_text=data["voice_text"],
                visual_ideas=json.dumps(
                    data.get("visual_ideas", []),
                    ensure_ascii=False,
                ),
                activities=json.dumps(
                    data.get("activities", []),
                    ensure_ascii=False,
                ),
                real_life_activity=data.get("real_life_activity", ""),
                review_voice=data.get("review_voice", ""),
                reward_stars=data.get("reward_stars", 10),
            )

            db.add(lesson)
            db.commit()
            generated.append(day_number)

        except Exception as exc:
            db.rollback()
            failed.append({
                "day": day_number,
                "error": str(exc),
            })

    return {
        "message": "60-day learning generation completed",
        "generated_days": generated,
        "skipped_existing_days": skipped,
        "failed_days": failed,
        "total_generated": len(generated),
        "total_skipped": len(skipped),
        "total_failed": len(failed),
    }


# =========================================================
# EXISTING ROUTERS
# =========================================================

app.include_router(children_router)
app.include_router(parent_router)
app.include_router(learning_router)
app.include_router(quiz_router)
app.include_router(auth_router)
app.include_router(admin_router)


# =========================================================
# ADMIN DASHBOARD
# =========================================================

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
def admin_dashboard():

    return r"""
<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
>

<title>ChildSafe AI - Admin Dashboard</title>


<style>

/* =========================================================
   RESET
========================================================= */

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {

    font-family:
        "Segoe UI",
        Arial,
        sans-serif;

    background: #f6f8fc;

    color: #26344d;

}


/* =========================================================
   SIDEBAR
========================================================= */

.sidebar {

    position: fixed;

    left: 0;
    top: 0;
    bottom: 0;

    width: 245px;

    background: white;

    border-right: 1px solid #e7ebf2;

    padding: 20px 14px;

    z-index: 100;

}


.logo {

    padding: 5px 12px 22px;

    border-bottom: 1px solid #edf0f5;

}


.logo-main {

    display: flex;

    align-items: center;

    gap: 10px;

}


.logo-icon {

    width: 44px;
    height: 44px;

    border-radius: 13px;

    background:
        linear-gradient(
            135deg,
            #667eea,
            #7659e8
        );

    display: flex;

    align-items: center;
    justify-content: center;

    font-size: 22px;

}


.logo h2 {

    font-size: 18px;

    color: #26344d;

}


.logo p {

    font-size: 10px;

    color: #929caf;

    margin-top: 3px;

}


.menu {

    margin-top: 20px;

}


.menu-title {

    font-size: 10px;

    color: #a1a9b8;

    font-weight: 700;

    margin:
        18px 12px 8px;

    text-transform: uppercase;

}


.menu-item {

    display: flex;

    align-items: center;

    gap: 12px;

    padding:
        12px 13px;

    margin-bottom: 5px;

    border-radius: 11px;

    color: #667085;

    cursor: pointer;

    font-size: 13px;

    transition: .2s;

}


.menu-item:hover {

    background: #f0f3ff;

    color: #536ee9;

}


.menu-item.active {

    background: #edf1ff;

    color: #536ee9;

    font-weight: 700;

}


.menu-icon {

    width: 25px;

    text-align: center;

    font-size: 18px;

}


/* =========================================================
   MAIN
========================================================= */

.main {

    margin-left: 245px;

    min-height: 100vh;

}


/* =========================================================
   TOPBAR
========================================================= */

.topbar {

    height: 72px;

    background: white;

    border-bottom:
        1px solid #e7ebf2;

    display: flex;

    align-items: center;

    justify-content: space-between;

    padding:
        0 30px;

    position: sticky;

    top: 0;

    z-index: 50;

}


.page-title h3 {

    font-size: 18px;

}


.page-title p {

    font-size: 10px;

    color: #9aa3b5;

    margin-top: 3px;

}


/* =========================================================
   TOP RIGHT
========================================================= */

.top-right {

    display: flex;

    align-items: center;

    gap: 15px;

}


.authorize-btn {

    border: none;

    padding:
        10px 16px;

    border-radius: 10px;

    background: #edf2ff;

    color: #536ee9;

    font-size: 12px;

    font-weight: 700;

    cursor: pointer;

}


.authorize-btn:hover {

    background: #dfe7ff;

}


.authorize-btn.authorized {

    background: #e7f9ef;

    color: #24965a;

}


.admin {

    display: flex;

    align-items: center;

    gap: 9px;

}


.avatar {

    width: 38px;
    height: 38px;

    border-radius: 50%;

    background:
        linear-gradient(
            135deg,
            #667eea,
            #7659e8
        );

    color: white;

    display: flex;

    align-items: center;
    justify-content: center;

    font-weight: 700;

}


.admin-name {

    font-size: 12px;

    font-weight: 700;

}


.admin-role {

    font-size: 9px;

    color: #9aa3b5;

}


/* =========================================================
   CONTENT
========================================================= */

.content {

    padding: 30px;

}


/* =========================================================
   WELCOME
========================================================= */

.welcome {

    padding: 28px 30px;

    border-radius: 20px;

    background:
        linear-gradient(
            135deg,
            #667eea,
            #7659e8
        );

    color: white;

    margin-bottom: 24px;

}


.welcome h1 {

    font-size: 24px;

    margin-bottom: 7px;

}


.welcome p {

    font-size: 12px;

    color: #eef0ff;

}


/* =========================================================
   STATS
========================================================= */

.stats {

    display: grid;

    grid-template-columns:
        repeat(4, 1fr);

    gap: 16px;

    margin-bottom: 24px;

}


.stat {

    background: white;

    border: 1px solid #e9edf4;

    border-radius: 15px;

    padding: 18px;

}


.stat-icon {

    width: 42px;
    height: 42px;

    border-radius: 12px;

    display: flex;

    align-items: center;
    justify-content: center;

    font-size: 20px;

    background: #eef2ff;

}


.stat-label {

    font-size: 10px;

    color: #929caf;

    margin-top: 15px;

}


.stat-value {

    font-size: 25px;

    font-weight: 700;

    margin-top: 4px;

}


/* =========================================================
   PANELS
========================================================= */

.grid {

    display: grid;

    grid-template-columns:
        1.5fr 1fr;

    gap: 20px;

}


.panel {

    background: white;

    border: 1px solid #e7ebf2;

    border-radius: 15px;

    overflow: hidden;

}


.panel-head {

    padding:
        17px 20px;

    border-bottom:
        1px solid #edf0f5;

    display: flex;

    justify-content: space-between;

    align-items: center;

}


.panel-head h2 {

    font-size: 14px;

}


.panel-head span {

    font-size: 10px;

    color: #929caf;

}


/* =========================================================
   CHILD ROW
========================================================= */

.child-row {

    display: flex;

    align-items: center;

    justify-content: space-between;

    padding:
        14px 20px;

    border-bottom:
        1px solid #f0f2f6;

}


.child-info {

    display: flex;

    align-items: center;

    gap: 10px;

}


.child-avatar {

    width: 38px;
    height: 38px;

    border-radius: 11px;

    background: #eef2ff;

    display: flex;

    align-items: center;
    justify-content: center;

}


.child-name {

    font-size: 12px;

    font-weight: 700;

}


.child-age {

    font-size: 9px;

    color: #929caf;

    margin-top: 2px;

}


.status {

    padding:
        5px 9px;

    border-radius: 20px;

    font-size: 9px;

    font-weight: 700;

}


.active {

    background: #e7f9ef;

    color: #26965a;

}


.inactive {

    background: #fff0f0;

    color: #d34848;

}


/* =========================================================
   ACTIVITY
========================================================= */

.activity {

    padding: 20px;

}


.activity-row {

    display: flex;

    gap: 12px;

    margin-bottom: 20px;

}


.activity-icon {

    width: 35px;
    height: 35px;

    background: #eef2ff;

    border-radius: 10px;

    display: flex;

    align-items: center;
    justify-content: center;

}


.activity-text {

    font-size: 11px;

}


.activity-time {

    font-size: 9px;

    color: #9aa3b5;

    margin-top: 3px;

}


/* =========================================================
   MODULE
========================================================= */

#modulePage {

    display: none;

}


.toolbar {

    padding: 18px 20px;

    display: flex;

    align-items: center;

    justify-content: space-between;

    border-bottom:
        1px solid #edf0f5;

}


.toolbar-left h2 {

    font-size: 16px;

}


.toolbar-left p {

    font-size: 10px;

    color: #929caf;

    margin-top: 3px;

}


.toolbar-right {

    display: flex;

    gap: 8px;

}


.search {

    width: 250px;

    padding:
        10px 12px;

    border:
        1px solid #dfe4ec;

    border-radius: 9px;

    outline: none;

    font-size: 11px;

}


.btn {

    border: none;

    border-radius: 9px;

    padding:
        10px 14px;

    font-size: 11px;

    font-weight: 700;

    cursor: pointer;

}


.btn-primary {

    background:
        linear-gradient(
            135deg,
            #667eea,
            #7659e8
        );

    color: white;

}


.btn-edit {

    background: #fff5df;

    color: #a46b00;

}


.btn-delete {

    background: #fff0f0;

    color: #d34848;

}


.table-wrap {

    overflow-x: auto;

}


table {

    width: 100%;

    border-collapse: collapse;

}


th {

    background: #fafbfe;

    color: #8993a7;

    font-size: 9px;

    text-align: left;

    padding:
        13px 15px;

}


td {

    padding:
        13px 15px;

    border-top:
        1px solid #edf0f5;

    font-size: 10px;

    color: #4e5b70;

}


.actions {

    display: flex;

    gap: 5px;

}


/* =========================================================
   MODAL
========================================================= */

.modal {

    position: fixed;

    inset: 0;

    background:
        rgba(
            20,
            27,
            45,
            .5
        );

    display: none;

    align-items: center;

    justify-content: center;

    z-index: 1000;

}


.modal-box {

    width: 530px;

    max-width: 92%;

    max-height: 90vh;

    overflow-y: auto;

    background: white;

    border-radius: 18px;

    padding: 25px;

}


.modal-header {

    display: flex;

    align-items: center;

    justify-content: space-between;

    margin-bottom: 18px;

}


.modal-header h2 {

    font-size: 18px;

}


.close {

    font-size: 25px;

    color: #8993a7;

    cursor: pointer;

}


.form-group {

    margin-bottom: 14px;

}


.form-group label {

    display: block;

    font-size: 10px;

    font-weight: 700;

    color: #59657a;

    margin-bottom: 6px;

}


.form-control {

    width: 100%;

    padding:
        11px;

    border:
        1px solid #dfe4ec;

    border-radius: 8px;

    outline: none;

    font-size: 12px;

}


.modal-footer {

    display: flex;

    justify-content: flex-end;

    gap: 8px;

    margin-top: 20px;

}


.loading {

    padding: 40px;

    text-align: center;

    color: #929caf;

    font-size: 11px;

}


.error {

    padding: 30px;

    text-align: center;

    color: #d34848;

    font-size: 11px;

}


/* =========================================================
   RESPONSIVE
========================================================= */

@media(max-width:1050px) {

    .stats {

        grid-template-columns:
            repeat(2, 1fr);

    }

    .grid {

        grid-template-columns: 1fr;

    }

}


@media(max-width:700px) {

    .sidebar {

        width: 70px;

    }

    .logo h2,
    .logo p,
    .menu-title,
    .menu-item span:last-child {

        display: none;

    }

    .main {

        margin-left: 70px;

    }

    .content {

        padding: 15px;

    }

    .stats {

        grid-template-columns: 1fr;

    }

    .toolbar {

        flex-direction: column;

        align-items: stretch;

        gap: 12px;

    }

    .toolbar-right {

        width: 100%;

    }

    .search {

        width: 100%;

    }

}

</style>

</head>


<body>


<!-- =========================================================
     SIDEBAR
========================================================= -->

<div class="sidebar">

    <div class="logo">

        <div class="logo-main">

            <div class="logo-icon">
                🛡️
            </div>

            <div>

                <h2>ChildSafe AI</h2>

                <p>Safe • Learn • Grow</p>

            </div>

        </div>

    </div>


    <div class="menu">

        <div class="menu-title">
            Overview
        </div>


        <div
            class="menu-item active"
            onclick="showDashboard(this)"
        >

            <span class="menu-icon">
                🏠
            </span>

            <span>
                Dashboard
            </span>

        </div>


        <div class="menu-title">
            Management
        </div>


        <div
            class="menu-item"
            onclick="showModule('children', this)"
        >

            <span class="menu-icon">
                👧
            </span>

            <span>
                Children
            </span>

        </div>


        <div
            class="menu-item"
            onclick="showModule('parents', this)"
        >

            <span class="menu-icon">
                👨‍👩‍👧
            </span>

            <span>
                Parents
            </span>

        </div>


        <div
            class="menu-item"
            onclick="showModule('learning', this)"
        >

            <span class="menu-icon">
                📚
            </span>

            <span>
                Learning
            </span>

        </div>


        <div
            class="menu-item"
            onclick="showModule('quiz', this)"
        >

            <span class="menu-icon">
                📝
            </span>

            <span>
                Quiz
            </span>

        </div>


        <div
            class="menu-item"
            onclick="showModule('safety', this)"
        >

            <span class="menu-icon">
                🛡️
            </span>

            <span>
                Safety
            </span>

        </div>


        <div class="menu-title">
            Developer
        </div>


        <div
            class="menu-item"
            onclick="openSwagger()"
        >

            <span class="menu-icon">
                ⚙️
            </span>

            <span>
                API Documentation
            </span>

        </div>

    </div>

</div>


<!-- =========================================================
     MAIN
========================================================= -->

<div class="main">


    <!-- TOPBAR -->

    <div class="topbar">

        <div class="page-title">

            <h3 id="pageTitle">
                Dashboard
            </h3>

            <p>
                Child Safety & Learning Management
            </p>

        </div>


        <div class="top-right">


            <!-- AUTHORIZE -->

            <button
                id="authorizeButton"
                class="authorize-btn"
                onclick="openAuthorize()"
            >
                🔐 Authorize
            </button>


            <div class="admin">

                <div>

                    <div class="admin-name">
                        Administrator
                    </div>

                    <div class="admin-role">
                        System Admin
                    </div>

                </div>

                <div class="avatar">
                    A
                </div>

            </div>

        </div>

    </div>


    <!-- CONTENT -->

    <div class="content">


        <!-- =================================================
             DASHBOARD
        ================================================= -->

        <div id="dashboardPage">


            <div class="welcome">

                <h1>
                    Welcome back, Admin! 👋
                </h1>

                <p>
                    Monitor children, parents,
                    learning and safety from one place.
                </p>

            </div>


            <div class="stats">


                <div class="stat">

                    <div class="stat-icon">
                        👧
                    </div>

                    <div class="stat-label">
                        TOTAL CHILDREN
                    </div>

                    <div
                        class="stat-value"
                        id="totalChildren"
                    >
                        —
                    </div>

                </div>


                <div class="stat">

                    <div class="stat-icon">
                        👨‍👩‍👧
                    </div>

                    <div class="stat-label">
                        TOTAL PARENTS
                    </div>

                    <div
                        class="stat-value"
                        id="totalParents"
                    >
                        —
                    </div>

                </div>


                <div class="stat">

                    <div class="stat-icon">
                        🟢
                    </div>

                    <div class="stat-label">
                        ACTIVE CHILDREN
                    </div>

                    <div
                        class="stat-value"
                        id="activeChildren"
                    >
                        —
                    </div>

                </div>


                <div class="stat">

                    <div class="stat-icon">
                        📝
                    </div>

                    <div class="stat-label">
                        QUIZ RECORDS
                    </div>

                    <div
                        class="stat-value"
                        id="totalQuiz"
                    >
                        —
                    </div>

                </div>


            </div>


            <div class="grid">


                <div class="panel">

                    <div class="panel-head">

                        <h2>
                            👧 Recent Children
                        </h2>

                        <span>
                            Live API Data
                        </span>

                    </div>


                    <div id="recentChildren">

                        <div class="loading">
                            Please authorize to load data...
                        </div>

                    </div>

                </div>


                <div class="panel">

                    <div class="panel-head">

                        <h2>
                            🛡️ System Activity
                        </h2>

                    </div>


                    <div class="activity">


                        <div class="activity-row">

                            <div class="activity-icon">
                                🔐
                            </div>

                            <div>

                                <div class="activity-text">
                                    API Authorization
                                </div>

                                <div
                                    class="activity-time"
                                    id="authStatusText"
                                >
                                    Waiting for authorization
                                </div>

                            </div>

                        </div>


                        <div class="activity-row">

                            <div class="activity-icon">
                                📚
                            </div>

                            <div>

                                <div class="activity-text">
                                    Learning System
                                </div>

                                <div class="activity-time">
                                    Connected to FastAPI
                                </div>

                            </div>

                        </div>


                        <div class="activity-row">

                            <div class="activity-icon">
                                📝
                            </div>

                            <div>

                                <div class="activity-text">
                                    Quiz System
                                </div>

                                <div class="activity-time">
                                    Connected to FastAPI
                                </div>

                            </div>

                        </div>


                    </div>

                </div>


            </div>

        </div>


        <!-- =================================================
             MODULE PAGE
        ================================================= -->

        <div id="modulePage">


            <div class="panel">


                <div class="toolbar">


                    <div class="toolbar-left">

                        <h2 id="moduleTitle">
                            Children
                        </h2>

                        <p id="moduleSubtitle">
                            Manage records
                        </p>

                    </div>


                    <div class="toolbar-right">

                        <input
                            id="searchInput"
                            class="search"
                            placeholder="🔎 Search..."
                            onkeyup="searchTable()"
                        >


                        <button
                            class="btn btn-primary"
                            onclick="openAddForm()"
                        >
                            + Add
                        </button>

                    </div>


                </div>


                <div
                    id="tableArea"
                    class="table-wrap"
                >

                    <div class="loading">
                        Loading...
                    </div>

                </div>


            </div>

        </div>


    </div>

</div>


<!-- =========================================================
     AUTHORIZE MODAL
========================================================= -->

<div
    id="authorizeModal"
    class="modal"
>

    <div class="modal-box">


        <div class="modal-header">

            <h2>
                🔐 API Authorization
            </h2>

            <span
                class="close"
                onclick="closeAuthorize()"
            >
                ×
            </span>

        </div>


        <p style="
            font-size:11px;
            color:#7d8799;
            line-height:1.6;
            margin-bottom:18px;
        ">

            Login with the same credentials
            you use in your FastAPI authentication.
            The dashboard will automatically obtain
            the JWT token and use it for API requests.

        </p>


        <div class="form-group">

            <label>
                Username
            </label>

            <input
                id="authUsername"
                class="form-control"
                type="text"
                placeholder="Enter username"
            >

        </div>


        <div class="form-group">

            <label>
                Password
            </label>

            <input
                id="authPassword"
                class="form-control"
                type="password"
                placeholder="Enter password"
            >

        </div>


        <div
            id="authError"
            style="
                display:none;
                background:#fff0f0;
                color:#d34848;
                padding:10px;
                border-radius:8px;
                font-size:10px;
                margin-top:10px;
            "
        ></div>


        <div class="modal-footer">


            <button
                class="btn"
                onclick="clearAuthorization()"
                style="
                    background:#fff0f0;
                    color:#d34848;
                "
            >
                Logout
            </button>


            <button
                id="loginButton"
                class="btn btn-primary"
                onclick="authorizeLogin()"
            >
                🔐 Authorize
            </button>


        </div>


    </div>

</div>


<!-- =========================================================
     ADD / EDIT MODAL
========================================================= -->

<div
    id="formModal"
    class="modal"
>

    <div class="modal-box">


        <div class="modal-header">

            <h2 id="formTitle">
                Add Record
            </h2>

            <span
                class="close"
                onclick="closeFormModal()"
            >
                ×
            </span>

        </div>


        <div id="formArea"></div>


        <div class="modal-footer">

            <button
                class="btn"
                onclick="closeFormModal()"
                style="
                    background:#eef1f6;
                    color:#687386;
                "
            >
                Cancel
            </button>


            <button
                id="saveButton"
                class="btn btn-primary"
                onclick="saveRecord()"
            >
                Save
            </button>

        </div>


    </div>

</div>


<script>

/* =========================================================
   GLOBAL VARIABLES
========================================================= */

let authToken =
    localStorage.getItem(
        "childsafe_token"
    );


let currentModule = null;

let currentRecords = [];

let currentCollectionPath = null;

let currentOperation = null;

let currentRecordId = null;


/* =========================================================
   MODULE NAMES
========================================================= */

const moduleConfig = {

    children: {

        title: "👧 Children",

        keywords: [
            "child",
            "children"
        ]

    },


    parents: {

        title: "👨‍👩‍👧 Parents",

        keywords: [
            "parent"
        ]

    },


    learning: {

        title: "📚 Learning",

        keywords: [
            "learning"
        ]

    },


    quiz: {

        title: "📝 Quiz",

        keywords: [
            "quiz"
        ]

    },


    safety: {

        title: "🛡️ Safety",

        keywords: [
            "safety"
        ]

    }

};


/* =========================================================
   API REQUEST
========================================================= */

async function apiRequest(
    url,
    options = {}
) {

    options.headers =
        options.headers || {};


    if (authToken) {

        options.headers[
            "Authorization"
        ] =
            "Bearer " + authToken;

    }


    const response =
        await fetch(
            url,
            options
        );


    if (
        response.status === 401
    ) {

        authToken = null;

        localStorage.removeItem(
            "childsafe_token"
        );

        updateAuthUI();

        showAuthError(
            "Authorization expired. Please login again."
        );

    }


    return response;

}


/* =========================================================
   GET OPENAPI
========================================================= */

let openApiCache = null;


async function getOpenAPI() {

    if (openApiCache) {

        return openApiCache;

    }


    const response =
        await fetch(
            "/openapi.json"
        );


    if (!response.ok) {

        throw new Error(
            "Unable to load OpenAPI."
        );

    }


    openApiCache =
        await response.json();


    return openApiCache;

}


/* =========================================================
   FIND AUTH TOKEN URL
========================================================= */

async function findTokenURL() {

    const api =
        await getOpenAPI();


    const schemes =
        (
            api.components &&
            api.components.securitySchemes
        )
        || {};


    /*
       First find OAuth2 scheme.
    */

    for (
        const [
            name,
            scheme
        ]
        of Object.entries(
            schemes
        )
    ) {

        if (
            scheme.type ===
            "oauth2"
        ) {

            const flows =
                scheme.flows || {};


            if (
                flows.password &&
                flows.password.tokenUrl
            ) {

                return flows.password.tokenUrl;

            }


            if (
                flows.clientCredentials &&
                flows.clientCredentials.tokenUrl
            ) {

                return flows.clientCredentials.tokenUrl;

            }

        }

    }


    /*
       Common FastAPI fallback.
    */

    const possible =
        [
            "/auth/token",
            "/token",
            "/login"
        ];


    for (
        const path
        of possible
    ) {

        if (
            api.paths &&
            api.paths[path]
        ) {

            return path;

        }

    }


    return null;

}


/* =========================================================
   AUTHORIZE LOGIN
========================================================= */

async function authorizeLogin() {

    const username =
        document
            .getElementById(
                "authUsername"
            )
            .value
            .trim();


    const password =
        document
            .getElementById(
                "authPassword"
            )
            .value;


    if (
        !username ||
        !password
    ) {

        showAuthError(
            "Please enter username and password."
        );

        return;

    }


    const loginButton =
        document
            .getElementById(
                "loginButton"
            );


    loginButton.disabled =
        true;


    loginButton.innerText =
        "Authorizing...";


    try {


        const tokenURL =
            await findTokenURL();


        if (!tokenURL) {

            throw new Error(
                "OAuth2 token endpoint was not found in OpenAPI."
            );

        }


        /*
           FastAPI OAuth2PasswordRequestForm
           requires application/x-www-form-urlencoded
        */

        const formData =
            new URLSearchParams();


        formData.append(
            "username",
            username
        );


        formData.append(
            "password",
            password
        );


        const response =
            await fetch(
                tokenURL,
                {

                    method:
                        "POST",

                    headers: {

                        "Content-Type":
                            "application/x-www-form-urlencoded"

                    },

                    body:
                        formData.toString()

                }
            );


        const result =
            await response.json();


        if (!response.ok) {

            let message =
                "Login failed.";


            if (
                result.detail
            ) {

                if (
                    Array.isArray(
                        result.detail
                    )
                ) {

                    message =
                        result.detail
                            .map(
                                x =>
                                x.msg
                            )
                            .join(
                                ", "
                            );

                }

                else {

                    message =
                        String(
                            result.detail
                        );

                }

            }


            throw new Error(
                message
            );

        }


        /*
           Standard FastAPI token response:

           {
             "access_token": "...",
             "token_type": "bearer"
           }
        */

        if (
            !result.access_token
        ) {

            throw new Error(
                "Login succeeded but access_token was not returned."
            );

        }


        authToken =
            result.access_token;


        localStorage.setItem(
            "childsafe_token",
            authToken
        );


        updateAuthUI();


        closeAuthorize();


        document
            .getElementById(
                "authUsername"
            )
            .value = "";


        document
            .getElementById(
                "authPassword"
            )
            .value = "";


        alert(
            "Authorized successfully! 🔐"
        );


        await loadDashboard();


        if (
            currentModule
        ) {

            await loadModule(
                currentModule
            );

        }

    }

    catch(error) {

        showAuthError(
            error.message
        );

    }

    finally {

        loginButton.disabled =
            false;

        loginButton.innerText =
            "🔐 Authorize";

    }

}


/* =========================================================
   AUTH UI
========================================================= */

function updateAuthUI() {

    const button =
        document
            .getElementById(
                "authorizeButton"
            );


    const status =
        document
            .getElementById(
                "authStatusText"
            );


    if (
        authToken
    ) {

        button.innerText =
            "🟢 Authorized";

        button.classList.add(
            "authorized"
        );


        if (status) {

            status.innerText =
                "API authorized successfully";

        }

    }

    else {

        button.innerText =
            "🔐 Authorize";

        button.classList.remove(
            "authorized"
        );


        if (status) {

            status.innerText =
                "Waiting for authorization";

        }

    }

}


/* =========================================================
   AUTHORIZE MODAL
========================================================= */

function openAuthorize() {

    document
        .getElementById(
            "authorizeModal"
        )
        .style.display =
        "flex";


    document
        .getElementById(
            "authError"
        )
        .style.display =
        "none";

}


function closeAuthorize() {

    document
        .getElementById(
            "authorizeModal"
        )
        .style.display =
        "none";

}


function showAuthError(
    message
) {

    const error =
        document
            .getElementById(
                "authError"
            );


    error.innerText =
        message;


    error.style.display =
        "block";


    document
        .getElementById(
            "authorizeModal"
        )
        .style.display =
        "flex";

}


/* =========================================================
   LOGOUT
========================================================= */

function clearAuthorization() {

    authToken =
        null;


    localStorage.removeItem(
        "childsafe_token"
    );


    updateAuthUI();


    closeAuthorize();


    document
        .getElementById(
            "totalChildren"
        )
        .innerText =
        "—";


    document
        .getElementById(
            "totalParents"
        )
        .innerText =
        "—";


    document
        .getElementById(
            "activeChildren"
        )
        .innerText =
        "—";


    document
        .getElementById(
            "totalQuiz"
        )
        .innerText =
        "—";


    document
        .getElementById(
            "recentChildren"
        )
        .innerHTML = `

            <div class="loading">

                Please authorize to load data.

            </div>

        `;

}


/* =========================================================
   FIND COLLECTION ENDPOINT
========================================================= */

async function findCollectionEndpoint(
    module
) {

    const api =
        await getOpenAPI();


    const keywords =
        moduleConfig[
            module
        ].keywords;


    const candidates =
        [];


    for (
        const [
            path,
            methods
        ]
        of Object.entries(
            api.paths || {}
        )
    ) {

        const lowerPath =
            path.toLowerCase();


        const match =
            keywords.some(
                keyword =>
                lowerPath.includes(
                    keyword
                )
            );


        if (!match) {

            continue;

        }


        /*
           Collection endpoint must NOT
           contain {id}.
        */

        if (
            path.includes("{")
        ) {

            continue;

        }


        if (
            methods.get
        ) {

            candidates.push({

                path: path,

                methods: methods

            });

        }

    }


    if (
        candidates.length === 0
    ) {

        return null;

    }


    /*
       Prefer shorter path.

       Example:

       /children
       /api/children

       /children is preferred.
    */

    candidates.sort(
        (
            a,
            b
        ) =>
        a.path.length -
        b.path.length
    );


    return candidates[0];

}


/* =========================================================
   GET CHILDREN
========================================================= */

async function loadChildren() {

    // Admin dashboard reads all children directly from the same
    // SQLite database used by Flutter/FastAPI. No parent JWT is
    // required just to display the admin child list.
    const response = await fetch("/admin/children");

    if (!response.ok) {
        throw new Error(
            "Admin children API returned " + response.status
        );
    }

    const data = await response.json();

    return normalizeData(data);

}

/* =========================================================
   NORMALIZE DATA
========================================================= */

function normalizeData(
    data
) {

    if (
        Array.isArray(data)
    ) {

        return data;

    }


    if (
        data &&
        Array.isArray(
            data.items
        )
    ) {

        return data.items;

    }


    if (
        data &&
        Array.isArray(
            data.data
        )
    ) {

        return data.data;

    }


    if (
        data &&
        Array.isArray(
            data.children
        )
    ) {

        return data.children;

    }


    if (
        data &&
        Array.isArray(
            data.parents
        )
    ) {

        return data.parents;

    }


    if (
        data &&
        typeof data ===
        "object"
    ) {

        return [data];

    }


    return [];

}


/* =========================================================
   DASHBOARD
========================================================= */

async function loadDashboard() {

    if (!authToken) {

        return;

    }


    try {

        const children =
            await loadChildren();


        document
            .getElementById(
                "totalChildren"
            )
            .innerText =
            children.length;


        let active =
            0;


        children.forEach(
            child => {

            if (
                child.is_active ===
                true
                ||
                child.active ===
                true
                ||
                String(
                    child.status ||
                    ""
                ).toLowerCase()
                ===
                "active"
            ) {

                active++;

            }

        });


        document
            .getElementById(
                "activeChildren"
            )
            .innerText =
            active;


        showRecentChildren(
            children
        );


        const parents =
            await loadSimpleModule(
                "parents"
            );


        document
            .getElementById(
                "totalParents"
            )
            .innerText =
            parents.length;


        const quizzes =
            await loadSimpleModule(
                "quiz"
            );


        document
            .getElementById(
                "totalQuiz"
            )
            .innerText =
            quizzes.length;

    }

    catch(error) {

        console.error(
            error
        );

    }

}


/* =========================================================
   GENERIC MODULE LOAD
========================================================= */

async function loadSimpleModule(
    module
) {

    const endpoint =
        await findCollectionEndpoint(
            module
        );


    if (!endpoint) {

        return [];

    }


    const response =
        await apiRequest(
            endpoint.path
        );


    if (!response.ok) {

        return [];

    }


    const data =
        await response.json();


    return normalizeData(
        data
    );

}


/* =========================================================
   RECENT CHILDREN
========================================================= */

function showRecentChildren(
    children
) {

    const area =
        document
            .getElementById(
                "recentChildren"
            );


    if (
        children.length === 0
    ) {

        area.innerHTML = `

            <div class="loading">

                No children found.

            </div>

        `;

        return;

    }


    let html = "";


    children
        .slice(0, 6)
        .forEach(
            child => {

            const name =
                child.name ||
                child.child_name ||
                "Child";


            const age =
                child.age ??
                "—";


            const isActive =
                child.is_active === true ||
                child.active === true ||
                String(
                    child.status ||
                    ""
                ).toLowerCase()
                ===
                "active";


            html += `

                <div class="child-row">

                    <div class="child-info">

                        <div class="child-avatar">

                            ${age !== "—" &&
                              Number(age) < 10
                              ? "👧"
                              : "👦"}

                        </div>

                        <div>

                            <div class="child-name">

                                ${escapeHtml(
                                    name
                                )}

                            </div>

                            <div class="child-age">

                                Age: ${escapeHtml(
                                    age
                                )}

                            </div>

                        </div>

                    </div>


                    <span class="
                        status
                        ${
                            isActive
                            ? "active"
                            : "inactive"
                        }
                    ">

                        ${
                            isActive
                            ? "● Active"
                            : "● Inactive"
                        }

                    </span>

                </div>

            `;

        });


    area.innerHTML =
        html;

}


/* =========================================================
   DASHBOARD PAGE
========================================================= */

function showDashboard(
    element
) {

    document
        .getElementById(
            "dashboardPage"
        )
        .style.display =
        "block";


    document
        .getElementById(
            "modulePage"
        )
        .style.display =
        "none";


    document
        .getElementById(
            "pageTitle"
        )
        .innerText =
        "Dashboard";


    setActive(
        element
    );


    loadDashboard();

}


/* =========================================================
   MODULE PAGE
========================================================= */

async function showModule(
    module,
    element
) {

    currentModule =
        module;


    document
        .getElementById(
            "dashboardPage"
        )
        .style.display =
        "none";


    document
        .getElementById(
            "modulePage"
        )
        .style.display =
        "block";


    document
        .getElementById(
            "pageTitle"
        )
        .innerText =
        moduleConfig[
            module
        ].title;


    document
        .getElementById(
            "moduleTitle"
        )
        .innerText =
        moduleConfig[
            module
        ].title;


    document
        .getElementById(
            "moduleSubtitle"
        )
        .innerText =
        "Manage and monitor real API data";


    setActive(
        element
    );


    await loadModule(
        module
    );

}


/* =========================================================
   LOAD MODULE
========================================================= */

async function loadModule(
    module
) {

    const area =
        document
            .getElementById(
                "tableArea"
            );


    if (!authToken) {

        area.innerHTML = `

            <div class="loading">

                🔐 Please authorize first.

                <br><br>

                Click the
                <b>Authorize</b>
                button above.

            </div>

        `;

        return;

    }


    area.innerHTML = `

        <div class="loading">
            Loading ${module}...
        </div>

    `;


    try {

        // Children is special: the admin panel must show ALL children
        // from the database, not only the children belonging to the
        // parent account used for API authorization.
        if (module === "children") {

            currentCollectionPath = "/admin/children";

            const response = await fetch(
                "/admin/children"
            );

            if (!response.ok) {
                throw new Error(
                    "Admin children API returned " + response.status
                );
            }

            const data = await response.json();

            currentRecords = normalizeData(data);

            renderTable();
            return;
        }


        const endpoint =
            await findCollectionEndpoint(
                module
            );


        if (!endpoint) {

            throw new Error(
                "No collection GET endpoint found."
            );

        }


        currentCollectionPath =
            endpoint.path;


        const response =
            await apiRequest(
                endpoint.path
            );


        if (!response.ok) {

            throw new Error(
                "API returned " +
                response.status
            );

        }


        const data =
            await response.json();


        currentRecords =
            normalizeData(
                data
            );


        renderTable();

    }

    catch(error) {

        area.innerHTML = `

            <div class="error">

                ❌ ${escapeHtml(
                    error.message
                )}

            </div>

        `;

    }

}


/* =========================================================
   RENDER TABLE
========================================================= */

function renderTable() {

    const area =
        document
            .getElementById(
                "tableArea"
            );


    if (
        currentRecords.length === 0
    ) {

        area.innerHTML = `

            <div class="loading">
                No records found.
            </div>

        `;

        return;

    }


    const keys =
        Object.keys(
            currentRecords[0]
        );


    let html =
        "<table><thead><tr>";


    keys.forEach(
        key => {

        html += `
            <th>
                ${escapeHtml(
                    key
                )}
            </th>
        `;

    });


    html += `
        <th>
            Actions
        </th>
    `;


    html +=
        "</tr></thead><tbody>";


    currentRecords.forEach(
        (
            record,
            index
        ) => {

        html += `
            <tr data-index="${index}">
        `;


        keys.forEach(
            key => {

            let value =
                record[key];


            if (
                typeof value ===
                "object"
                &&
                value !== null
            ) {

                value =
                    JSON.stringify(
                        value
                    );

            }


            html += `
                <td>
                    ${escapeHtml(
                        String(
                            value ??
                            ""
                        )
                    )}
                </td>
            `;

        });


        html += `

            <td>

                <div class="actions">

                    <button
                        class="btn btn-edit"
                        onclick="editRecord(${index})"
                    >
                        Edit
                    </button>


                    <button
                        class="btn btn-delete"
                        onclick="deleteRecord(${index})"
                    >
                        Delete
                    </button>

                </div>

            </td>

        `;


        html +=
            "</tr>";

    });


    html +=
        "</tbody></table>";


    area.innerHTML =
        html;

}


/* =========================================================
   FIND CRUD ENDPOINT
========================================================= */

async function findCrudEndpoint(
    module,
    method
) {

    const api =
        await getOpenAPI();


    const keywords =
        moduleConfig[
            module
        ].keywords;


    for (
        const [
            path,
            methods
        ]
        of Object.entries(
            api.paths || {}
        )
    ) {

        const lower =
            path.toLowerCase();


        const matches =
            keywords.some(
                keyword =>
                lower.includes(
                    keyword
                )
            );


        if (!matches) {

            continue;

        }


        if (
            methods[
                method
            ]
        ) {

            return {

                path: path,

                operation:
                    methods[
                        method
                    ]

            };

        }

    }


    return null;

}


/* =========================================================
   ADD
========================================================= */

async function openAddForm() {

    if (!authToken) {

        openAuthorize();

        return;

    }


    const endpoint =
        await findCrudEndpoint(
            currentModule,
            "post"
        );


    if (!endpoint) {

        alert(
            "POST endpoint not found."
        );

        return;

    }


    currentOperation =
        "POST";


    currentCollectionPath =
        endpoint.path;


    currentRecordId =
        null;


    document
        .getElementById(
            "formTitle"
        )
        .innerText =
        "Add " +
        moduleConfig[
            currentModule
        ].title;


    createDynamicForm(
        endpoint.operation,
        {}
    );


    document
        .getElementById(
            "formModal"
        )
        .style.display =
        "flex";

}


/* =========================================================
   EDIT
========================================================= */

async function editRecord(
    index
) {

    const record =
        currentRecords[
            index
        ];


    const id =
        getRecordId(
            record
        );


    if (
        id === null
    ) {

        alert(
            "Record ID not found."
        );

        return;

    }


    const endpoint =
        await findCrudEndpoint(
            currentModule,
            "put"
        );


    if (!endpoint) {

        alert(
            "PUT endpoint not found."
        );

        return;

    }


    currentOperation =
        "PUT";


    currentRecordId =
        id;


    currentCollectionPath =
        buildItemPath(
            endpoint.path,
            id
        );


    document
        .getElementById(
            "formTitle"
        )
        .innerText =
        "Edit " +
        moduleConfig[
            currentModule
        ].title;


    createDynamicForm(
        endpoint.operation,
        record
    );


    document
        .getElementById(
            "formModal"
        )
        .style.display =
        "flex";

}


/* =========================================================
   DELETE
========================================================= */

async function deleteRecord(
    index
) {

    if (!authToken) {

        openAuthorize();

        return;

    }


    const record =
        currentRecords[
            index
        ];


    const id =
        getRecordId(
            record
        );


    if (
        id === null
    ) {

        alert(
            "Record ID not found."
        );

        return;

    }


    if (
        !confirm(
            "Are you sure you want to delete this record?"
        )
    ) {

        return;

    }


    const endpoint =
        await findCrudEndpoint(
            currentModule,
            "delete"
        );


    if (!endpoint) {

        alert(
            "DELETE endpoint not found."
        );

        return;

    }


    const url =
        buildItemPath(
            endpoint.path,
            id
        );


    try {

        const response =
            await apiRequest(
                url,
                {
                    method:
                        "DELETE"
                }
            );


        if (!response.ok) {

            const text =
                await response.text();

            throw new Error(
                text ||
                "Delete failed"
            );

        }


        alert(
            "Deleted successfully."
        );


        await loadModule(
            currentModule
        );


        await loadDashboard();

    }

    catch(error) {

        alert(
            error.message
        );

    }

}


/* =========================================================
   GET RECORD ID
========================================================= */

function getRecordId(
    record
) {

    const possible =
        [
            "id",
            "child_id",
            "parent_id",
            "learning_id",
            "quiz_id",
            "safety_id"
        ];


    for (
        const key
        of possible
    ) {

        if (
            record[key] !==
            undefined &&
            record[key] !==
            null
        ) {

            return record[key];

        }

    }


    return null;

}


/* =========================================================
   BUILD ITEM PATH
========================================================= */

function buildItemPath(
    path,
    id
) {

    if (
        path.includes(
            "{id}"
        )
    ) {

        return path.replace(
            "{id}",
            encodeURIComponent(
                id
            )
        );

    }


    if (
        path.includes(
            "{child_id}"
        )
    ) {

        return path.replace(
            "{child_id}",
            encodeURIComponent(
                id
            )
        );

    }


    if (
        path.includes(
            "{parent_id}"
        )
    ) {

        return path.replace(
            "{parent_id}",
            encodeURIComponent(
                id
            )
        );

    }


    if (
        path.includes(
            "{learning_id}"
        )
    ) {

        return path.replace(
            "{learning_id}",
            encodeURIComponent(
                id
            )
        );

    }


    if (
        path.includes(
            "{quiz_id}"
        )
    ) {

        return path.replace(
            "{quiz_id}",
            encodeURIComponent(
                id
            )
        );

    }


    if (
        path.includes(
            "{safety_id}"
        )
    ) {

        return path.replace(
            "{safety_id}",
            encodeURIComponent(
                id
            )
        );

    }


    return (
        path.replace(
            /\/$/,
            ""
        )
        +
        "/" +
        encodeURIComponent(
            id
        )
    );

}


/* =========================================================
   CREATE FORM
========================================================= */

function createDynamicForm(
    operation,
    record
) {

    const area =
        document
            .getElementById(
                "formArea"
            );


    let schema =
        null;


    if (
        operation &&
        operation.requestBody &&
        operation.requestBody.content &&
        operation.requestBody.content[
            "application/json"
        ]
    ) {

        schema =
            operation
                .requestBody
                .content[
                    "application/json"
                ]
                .schema;

    }


    if (!schema) {

        area.innerHTML = `

            <div class="form-group">

                <label>
                    JSON DATA
                </label>

                <textarea
                    id="jsonInput"
                    class="form-control"
                    rows="10"
                >${escapeHtml(
                    JSON.stringify(
                        record,
                        null,
                        2
                    )
                )}</textarea>

            </div>

        `;

        return;

    }


    /*
       Resolve schema references
    */

    if (
        schema.$ref
    ) {

        const refName =
            schema.$ref
                .split("/")
                .pop();


        const api =
            openApiCache;


        if (
            api.components &&
            api.components.schemas &&
            api.components.schemas[
                refName
            ]
        ) {

            schema =
                api.components.schemas[
                    refName
                ];

        }

    }


    const properties =
        schema.properties ||
        {};


    let html = "";


    Object.entries(
        properties
    ).forEach(
        (
            [
                key,
                property
            ]
        ) => {


        let value =
            record[key] ??
            "";


        if (
            key === "id" ||
            key.endsWith("_id")
        ) {

            /*
               Don't ask for generated ID
               while creating.
            */

            if (
                currentOperation ===
                "POST"
            ) {

                return;

            }

        }


        if (
            property.type ===
            "boolean"
        ) {

            html += `

                <div class="form-group">

                    <label>
                        ${escapeHtml(
                            key
                        )}
                    </label>

                    <select
                        class="form-control"
                        data-field="${escapeHtml(
                            key
                        )}"
                    >

                        <option
                            value="true"
                            ${
                                value ===
                                true
                                ? "selected"
                                : ""
                            }
                        >
                            True
                        </option>

                        <option
                            value="false"
                            ${
                                value ===
                                false
                                ? "selected"
                                : ""
                            }
                        >
                            False
                        </option>

                    </select>

                </div>

            `;

        }

        else if (
            property.type ===
            "integer"
            ||
            property.type ===
            "number"
        ) {

            html += `

                <div class="form-group">

                    <label>
                        ${escapeHtml(
                            key
                        )}
                    </label>

                    <input
                        type="number"
                        class="form-control"
                        data-field="${escapeHtml(
                            key
                        )}"
                        value="${escapeHtml(
                            value
                        )}"
                    >

                </div>

            `;

        }

        else {

            html += `

                <div class="form-group">

                    <label>
                        ${escapeHtml(
                            key
                        )}
                    </label>

                    <input
                        type="text"
                        class="form-control"
                        data-field="${escapeHtml(
                            key
                        )}"
                        value="${escapeHtml(
                            value
                        )}"
                    >

                </div>

            `;

        }

    });


    area.innerHTML =
        html;

}


/* =========================================================
   SAVE
========================================================= */

async function saveRecord() {

    if (!authToken) {

        openAuthorize();

        return;

    }


    let body = {};


    const jsonInput =
        document
            .getElementById(
                "jsonInput"
            );


    if (jsonInput) {

        try {

            body =
                JSON.parse(
                    jsonInput.value
                );

        }

        catch {

            alert(
                "Invalid JSON."
            );

            return;

        }

    }

    else {

        document
            .querySelectorAll(
                "#formArea [data-field]"
            )
            .forEach(
                input => {

                let value =
                    input.value;


                if (
                    input.tagName
                        .toLowerCase()
                    ===
                    "select"
                ) {

                    if (
                        value ===
                        "true"
                    ) {

                        value =
                            true;

                    }

                    else if (
                        value ===
                        "false"
                    ) {

                        value =
                            false;

                    }

                }


                body[
                    input.dataset.field
                ] =
                    value;

            });

    }


    let url =
        currentCollectionPath;


    try {

        const response =
            await apiRequest(
                url,
                {

                    method:
                        currentOperation,

                    headers: {

                        "Content-Type":
                            "application/json"

                    },

                    body:
                        JSON.stringify(
                            body
                        )

                }
            );


        const text =
            await response.text();


        let result =
            {};


        try {

            result =
                text
                ? JSON.parse(
                    text
                )
                : {};

        }

        catch {

            result = {
                message:
                    text
            };

        }


        if (!response.ok) {

            throw new Error(
                JSON.stringify(
                    result
                )
            );

        }


        alert(
            "Saved successfully! ✅"
        );


        closeFormModal();


        await loadModule(
            currentModule
        );


        await loadDashboard();

    }

    catch(error) {

        alert(
            "Save failed:\n\n" +
            error.message
        );

    }

}


/* =========================================================
   FORM MODAL
========================================================= */

function closeFormModal() {

    document
        .getElementById(
            "formModal"
        )
        .style.display =
        "none";

}


/* =========================================================
   SEARCH
========================================================= */

function searchTable() {

    const search =
        document
            .getElementById(
                "searchInput"
            )
            .value
            .toLowerCase();


    document
        .querySelectorAll(
            "#tableArea tbody tr"
        )
        .forEach(
            row => {

            row.style.display =
                row.innerText
                    .toLowerCase()
                    .includes(
                        search
                    )
                    ? ""
                    : "none";

        });

}


/* =========================================================
   ACTIVE MENU
========================================================= */

function setActive(
    element
) {

    document
        .querySelectorAll(
            ".menu-item"
        )
        .forEach(
            item => {

            item.classList.remove(
                "active"
            );

        });


    if (element) {

        element.classList.add(
            "active"
        );

    }

}


/* =========================================================
   SWAGGER
========================================================= */

function openSwagger() {

    window.open(
        "/docs",
        "_blank"
    );

}


/* =========================================================
   ESCAPE HTML
========================================================= */

function escapeHtml(
    value
) {

    return String(
        value ?? ""
    )
    .replace(
        /&/g,
        "&amp;"
    )
    .replace(
        /</g,
        "&lt;"
    )
    .replace(
        />/g,
        "&gt;"
    )
    .replace(
        /"/g,
        "&quot;"
    )
    .replace(
        /'/g,
        "&#039;"
    );

}


/* =========================================================
   START
========================================================= */

window.addEventListener(
    "load",
    async () => {

        updateAuthUI();


        /*
           If token already exists,
           automatically load data.
        */

        if (authToken) {

            await loadDashboard();

        }

    }
);

</script>

</body>
</html>
"""


# =========================================================
# HEALTH
# =========================================================

@app.get("/health")
def health():

    return {
        "status": "healthy"
    }

app = FastAPI(
    title="AI Learning API"
)


class LearningRequest(BaseModel):
    subject: str
    topic: str
    grade: int = 5
    language: str = "English"


@app.get("/")
def home():
    return {
        "message": "AI Learning API is running"
    }


@app.post("/learning/generate")
def generate_lesson(request: LearningRequest):

    try:

        lesson = generate_learning_content(
            subject=request.subject,
            topic=request.topic,
            grade=request.grade,
            language=request.language,
        )

        return {
            "success": True,
            "data": lesson
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )