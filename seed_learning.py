from database import SessionLocal, engine, Base
from models import LearningLesson


# =========================================================
# LEARNING DATA
# =========================================================

LEARNING_DATA = [

    # =====================================================
    # AGE 5 - 6
    # =====================================================

    {
        "subject": "English",
        "concept": "Alphabet",
        "title": "Learn A to Z",
        "description": "Learn the English alphabet from A to Z with simple examples.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 1,
    },

    {
        "subject": "English",
        "concept": "Words",
        "title": "Easy English Words",
        "description": "Learn simple everyday English words and their meanings.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 2,
    },

    {
        "subject": "Mathematics",
        "concept": "Numbers",
        "title": "Learn Numbers 1 to 20",
        "description": "Learn to recognize and count numbers from 1 to 20.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 1,
    },

    {
        "subject": "Mathematics",
        "concept": "Addition",
        "title": "Easy Addition",
        "description": "Learn basic addition using small numbers.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 2,
    },

    {
        "subject": "Science",
        "concept": "Animals",
        "title": "Amazing Animals",
        "description": "Learn about common animals and where they live.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 1,
    },

    {
        "subject": "Science",
        "concept": "Plants",
        "title": "Introduction to Plants",
        "description": "Learn about plants and the basic parts of a plant.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 2,
    },

    {
        "subject": "General Knowledge",
        "concept": "My World",
        "title": "My World",
        "description": "Learn about family, school, home and things around us.",
        "min_age": 5,
        "max_age": 6,
        "lesson_order": 1,
    },

    # =====================================================
    # AGE 7 - 8
    # =====================================================

    {
        "subject": "English",
        "concept": "Grammar",
        "title": "Basic Grammar",
        "description": "Learn nouns, verbs and simple sentence structures.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 1,
    },

    {
        "subject": "English",
        "concept": "Reading",
        "title": "Reading Practice",
        "description": "Improve reading skills using short and simple passages.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 2,
    },

    {
        "subject": "Mathematics",
        "concept": "Multiplication",
        "title": "Multiplication Basics",
        "description": "Learn simple multiplication and multiplication tables.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 1,
    },

    {
        "subject": "Mathematics",
        "concept": "Division",
        "title": "Introduction to Division",
        "description": "Understand simple division using everyday examples.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 2,
    },

    {
        "subject": "Science",
        "concept": "Human Body",
        "title": "Our Human Body",
        "description": "Learn about important parts of the human body.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 1,
    },

    {
        "subject": "Science",
        "concept": "Water",
        "title": "Water Around Us",
        "description": "Learn about water, its uses and the water cycle.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 2,
    },

    {
        "subject": "General Knowledge",
        "concept": "Geography",
        "title": "Our Earth",
        "description": "Learn basic facts about Earth, continents and oceans.",
        "min_age": 7,
        "max_age": 8,
        "lesson_order": 1,
    },

    # =====================================================
    # AGE 9 - 10
    # =====================================================

    {
        "subject": "English",
        "concept": "Tenses",
        "title": "Introduction to Tenses",
        "description": "Learn simple past, present and future tense.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 1,
    },

    {
        "subject": "English",
        "concept": "Vocabulary",
        "title": "Build Your Vocabulary",
        "description": "Learn new English words and improve vocabulary.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 2,
    },

    {
        "subject": "Mathematics",
        "concept": "Fractions",
        "title": "Understanding Fractions",
        "description": "Learn basic fractions using real-world examples.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 1,
    },

    {
        "subject": "Mathematics",
        "concept": "Decimals",
        "title": "Learn Decimals",
        "description": "Understand decimal numbers and simple decimal operations.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 2,
    },

    {
        "subject": "Science",
        "concept": "Matter",
        "title": "States of Matter",
        "description": "Learn about solids, liquids and gases.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 1,
    },

    {
        "subject": "Science",
        "concept": "Solar System",
        "title": "Our Solar System",
        "description": "Learn about the Sun, planets and our solar system.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 2,
    },

    {
        "subject": "General Knowledge",
        "concept": "World",
        "title": "Countries and Continents",
        "description": "Learn about countries, continents and important places.",
        "min_age": 9,
        "max_age": 10,
        "lesson_order": 1,
    },

    # =====================================================
    # AGE 11 - 13
    # =====================================================

    {
        "subject": "English",
        "concept": "Advanced Grammar",
        "title": "Advanced Grammar Basics",
        "description": "Improve grammar through sentence structure, parts of speech and usage.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 1,
    },

    {
        "subject": "English",
        "concept": "Writing",
        "title": "Creative Writing",
        "description": "Learn how to create interesting paragraphs and short stories.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 2,
    },

    {
        "subject": "Mathematics",
        "concept": "Algebra",
        "title": "Introduction to Algebra",
        "description": "Learn variables, expressions and simple algebraic equations.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 1,
    },

    {
        "subject": "Mathematics",
        "concept": "Geometry",
        "title": "Geometry Basics",
        "description": "Learn shapes, angles, lines and basic geometric concepts.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 2,
    },

    {
        "subject": "Science",
        "concept": "Energy",
        "title": "Understanding Energy",
        "description": "Learn about different forms of energy and how energy is used.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 1,
    },

    {
        "subject": "Science",
        "concept": "Environment",
        "title": "Our Environment",
        "description": "Learn about ecosystems, pollution and protecting our environment.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 2,
    },

    {
        "subject": "General Knowledge",
        "concept": "Technology",
        "title": "Technology Around Us",
        "description": "Learn how computers, the internet and modern technology are used.",
        "min_age": 11,
        "max_age": 13,
        "lesson_order": 1,
    },
]


# =========================================================
# SEED FUNCTION
# =========================================================

def seed_learning():

    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    added = 0
    skipped = 0

    try:

        for item in LEARNING_DATA:

            existing = (
                db.query(LearningLesson)
                .filter(
                    LearningLesson.subject == item["subject"],
                    LearningLesson.concept == item["concept"],
                    LearningLesson.title == item["title"],
                    LearningLesson.min_age == item["min_age"],
                    LearningLesson.max_age == item["max_age"],
                )
                .first()
            )

            if existing:
                skipped += 1
                continue

            lesson = LearningLesson(
                subject=item["subject"],
                concept=item["concept"],
                title=item["title"],
                description=item["description"],
                min_age=item["min_age"],
                max_age=item["max_age"],
                lesson_order=item["lesson_order"],
                is_active=True,
            )

            db.add(lesson)

            added += 1

        db.commit()

        print()
        print("========================================")
        print("LEARNING SEED COMPLETED")
        print("========================================")
        print(f"Lessons added   : {added}")
        print(f"Lessons skipped : {skipped}")
        print("========================================")
        print()

    except Exception as error:

        db.rollback()

        print()
        print("========================================")
        print("LEARNING SEED FAILED")
        print("========================================")
        print(error)
        print("========================================")
        print()

    finally:

        db.close()


# =========================================================
# RUN
# =========================================================

if __name__ == "__main__":
    seed_learning()