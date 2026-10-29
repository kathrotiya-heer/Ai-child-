import json
import requests


OLLAMA_URL = "http://localhost:11434/api/generate"

OLLAMA_MODEL = "llama3.2:3b"


def generate_learning_content(
    subject: str,
    topic: str,
    grade: int = 5,
    language: str = "English",
):

    prompt = f"""
You are a friendly AI teacher for children.

Create a complete and engaging learning lesson.

SUBJECT:
{subject}

TOPIC:
{topic}

GRADE:
{grade}

LANGUAGE:
{language}


IMPORTANT INSTRUCTIONS:

1. Explain the topic in simple language suitable for the given grade.

2. Give a detailed but easy-to-read explanation.

3. Give important key points.

4. Generate EXACTLY 10 examples.

5. Every example should contain:
   - question
   - visual
   - answer
   - step_by_step_explanation

6. Use child-friendly real-life objects in examples whenever appropriate.

7. You may use emojis such as:
   🍎 🍌 🍊 🚗 🚌 ⚽ 🐶 🐱 🌳 ⭐ 📚 ✏️

8. Do NOT force emojis into every question.
   Use them only when they help children understand the concept.

9. Generate EXACTLY 10 practice questions.

10. Each practice question should contain:
    - question
    - visual
    - answer
    - difficulty

11. Generate EXACTLY 10 multiple-choice quiz questions.

12. Every quiz question must contain:
    - question
    - visual
    - options
    - correct_answer
    - explanation

13. Every quiz question must have EXACTLY 4 options.

14. Make the questions progressively more challenging.

15. Keep everything child-friendly.

16. Avoid complicated words.

17. Return ONLY valid JSON.

18. Do NOT use markdown.

19. Do NOT write anything before or after the JSON.


RETURN THIS EXACT JSON STRUCTURE:

{{
    "subject": "{subject}",
    "topic": "{topic}",
    "grade": {grade},
    "language": "{language}",

    "explanation": "",

    "key_points": [
        ""
    ],

    "examples": [
        {{
            "question": "",
            "visual": "",
            "answer": "",
            "step_by_step_explanation": ""
        }}
    ],

    "practice_questions": [
        {{
            "question": "",
            "visual": "",
            "answer": "",
            "difficulty": ""
        }}
    ],

    "quiz": [
        {{
            "question": "",
            "visual": "",
            "options": [
                "",
                "",
                "",
                ""
            ],
            "correct_answer": "",
            "explanation": ""
        }}
    ]
}}
"""

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "format": "json",
        },
        timeout=300,
    )

    response.raise_for_status()

    result = response.json()

    content = result.get("response", "")

    return json.loads(content)