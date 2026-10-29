import ollama
import json
import os
import sys
import subprocess


# =========================================================
# PATH CONFIGURATION
# =========================================================

# backend folder
BACKEND_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

# main Flutter project folder
PROJECT_DIR = os.path.dirname(
    BACKEND_DIR
)

# Piper Hindi voice model
VOICE_MODEL = os.path.join(
    PROJECT_DIR,
    "hi_IN-priyamvada-medium.onnx"
)

# Generated audio folder
AUDIO_DIR = os.path.join(
    PROJECT_DIR,
    "generated_audio"
)


# =========================================================
# PIPER VOICE GENERATION
# =========================================================

def generate_voice(text, filename):

    if not text or not text.strip():

        raise ValueError(
            "Voice text is empty."
        )


    # Check Piper model

    if not os.path.exists(VOICE_MODEL):

        raise FileNotFoundError(
            "Piper voice model not found:\n"
            + VOICE_MODEL
        )


    # Create audio folder

    os.makedirs(
        AUDIO_DIR,
        exist_ok=True
    )


    output_path = os.path.join(
        AUDIO_DIR,
        filename
    )


    # IMPORTANT:
    # Use the currently active Python environment

    python_executable = sys.executable


    command = [
        python_executable,
        "-m",
        "piper",
        "-m",
        VOICE_MODEL,
        "-f",
        output_path,
        "--",
        text
    ]


    print()
    print("🎙️ Generating voice...")
    print("Text:", text)
    print("Output:", output_path)


    try:

        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )

    except Exception as e:

        print()
        print("❌ Could not start Piper.")
        print(e)

        raise


    # Check Piper error

    if result.returncode != 0:

        print()
        print("❌ Piper TTS failed.")

        if result.stderr:

            print()
            print("Piper Error:")
            print(result.stderr)


        raise RuntimeError(
            "Piper TTS failed:\n"
            + result.stderr
        )


    # Check file creation

    if not os.path.exists(
        output_path
    ):

        raise RuntimeError(
            "Piper finished, but "
            "audio file was not created."
        )


    print()
    print(
        "✅ Voice generated successfully!"
    )


    return output_path


# =========================================================
# GENERATE LEARNING DAY
# =========================================================

def generate_learning_day(
    day_number,
    category,
    skill,
    age_group="5-7"
):


    prompt = f"""
You are an AI educational content creator
for children aged {age_group}.

Create ONE daily learning session.

Day: {day_number}
Category: {category}
Skill: {skill}

The session must be designed for a young child
who may not be able to read properly.

The learning session should use:

- visual learning
- simple voice explanation
- interactive activities
- very little text
- real-life examples

The complete session should take
approximately 30 minutes.


=========================================================
IMPORTANT RULES
=========================================================

- Return ONLY valid JSON.
- Do not add markdown.
- Do not add explanations outside JSON.
- Do not use trailing commas.
- Use simple language suitable for children aged 5-7.
- Do not repeat the same activity.
- Make the activities visual and interactive.
- Do not create quizzes.
- Do not require typing.
- Do not require internet.
- Keep the lesson safe for children.


=========================================================
VOICE RULES
=========================================================

voice_text should sound like a friendly teacher
talking directly to a child.

Use short and simple sentences.

review_voice should congratulate the child
and briefly review what was learned.


=========================================================
VISUAL RULES
=========================================================

Create exactly 3 visual ideas.

The visual ideas should be suitable for:

- illustration
- AI image generation
- simple animation

Do not depend on written text inside the image.


=========================================================
ACTIVITY RULES
=========================================================

Create EXACTLY 3 activities.

The order MUST be:

1. tap
2. match
3. choose


=========================================================
TAP
=========================================================

Type must be:

"tap"

Use exactly 3 options.

correct_answer MUST exactly match
one of the options.


=========================================================
MATCH
=========================================================

Type must be:

"match"

Create EXACTLY 3 meaningful pairs.

Each pair must have:

"left"

and

"right"

The relationship must make sense.

Example:

Toy -> Toy Box

Book -> Bookshelf

Clothes -> Closet


=========================================================
CHOOSE
=========================================================

Type must be:

"choose"

Use exactly 3 options.

Only one option should be correct.

correct_answer MUST exactly match
one of the options.


=========================================================
SAFETY
=========================================================

Do not require:

- internet
- money
- personal phone
- dangerous objects
- sharp objects
- electrical equipment
- cooking


=========================================================
EXACT JSON STRUCTURE
=========================================================

{{
    "day": {day_number},

    "category": "{category}",

    "skill": "{skill}",

    "title": "",

    "age_group": "{age_group}",

    "duration_minutes": 30,

    "introduction": "",

    "voice_text": "",

    "visual_ideas": [
        "",
        "",
        ""
    ],

    "activities": [

        {{
            "type": "tap",

            "title": "",

            "instruction": "",

            "options": [
                "",
                "",
                ""
            ],

            "correct_answer": "",

            "estimated_minutes": 5
        }},

        {{
            "type": "match",

            "title": "",

            "instruction": "",

            "pairs": [
                {{
                    "left": "",
                    "right": ""
                }},
                {{
                    "left": "",
                    "right": ""
                }},
                {{
                    "left": "",
                    "right": ""
                }}
            ],

            "estimated_minutes": 5
        }},

        {{
            "type": "choose",

            "title": "",

            "instruction": "",

            "options": [
                "",
                "",
                ""
            ],

            "correct_answer": "",

            "estimated_minutes": 5
        }}

    ],

    "real_life_activity": "",

    "review_voice": "",

    "reward_stars": 10
}}

"""


    try:

        print()
        print(
            f"🤖 Generating Day {day_number}..."
        )


        # =====================================================
        # OLLAMA
        # =====================================================

        response = ollama.chat(

            model="llama3.2:3b",

            format="json",

            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )


        content = (
            response["message"]["content"]
            .strip()
        )


        # =====================================================
        # REMOVE MARKDOWN
        # =====================================================

        if content.startswith(
            "```json"
        ):

            content = content[7:]


        elif content.startswith(
            "```"
        ):

            content = content[3:]


        if content.endswith(
            "```"
        ):

            content = content[:-3]


        content = content.strip()


        # =====================================================
        # JSON PARSE
        # =====================================================

        learning_data = json.loads(
            content
        )


        print()
        print(
            "✅ Learning JSON generated!"
        )


        # =====================================================
        # BASIC VALIDATION
        # =====================================================

        required_fields = [

            "day",
            "category",
            "skill",
            "title",
            "age_group",
            "duration_minutes",
            "introduction",
            "voice_text",
            "visual_ideas",
            "activities",
            "real_life_activity",
            "review_voice",
            "reward_stars"

        ]


        missing_fields = [

            field

            for field in required_fields

            if field not in learning_data

        ]


        if missing_fields:

            print()
            print(
                "❌ Missing fields:"
            )

            print(
                missing_fields
            )

            return None


        # =====================================================
        # VISUAL VALIDATION
        # =====================================================

        if not isinstance(
            learning_data["visual_ideas"],
            list
        ):

            print(
                "❌ visual_ideas must be a list."
            )

            return None


        if len(
            learning_data["visual_ideas"]
        ) != 3:

            print(
                "❌ Exactly 3 visual ideas required."
            )

            return None


        # =====================================================
        # ACTIVITY VALIDATION
        # =====================================================

        activities = learning_data[
            "activities"
        ]


        if not isinstance(
            activities,
            list
        ):

            print(
                "❌ activities must be a list."
            )

            return None


        if len(activities) != 3:

            print(
                "❌ Exactly 3 activities required."
            )

            return None


        expected_types = [
            "tap",
            "match",
            "choose"
        ]


        actual_types = [

            activity.get("type")

            for activity in activities

        ]


        if actual_types != expected_types:

            print()
            print(
                "❌ Activity order/type incorrect."
            )

            print(
                "Expected:",
                expected_types
            )

            print(
                "Received:",
                actual_types
            )

            return None


        # =====================================================
        # TAP VALIDATION
        # =====================================================

        tap_activity = activities[0]


        tap_options = tap_activity.get(
            "options"
        )


        if not isinstance(
            tap_options,
            list
        ) or len(tap_options) != 3:

            print(
                "❌ Tap must have exactly 3 options."
            )

            return None


        if tap_activity.get(
            "correct_answer"
        ) not in tap_options:

            print(
                "❌ Tap correct_answer "
                "must match an option."
            )

            return None


        # =====================================================
        # MATCH VALIDATION
        # =====================================================

        match_activity = activities[1]


        pairs = match_activity.get(
            "pairs"
        )


        if not isinstance(
            pairs,
            list
        ):

            print(
                "❌ Match pairs must be a list."
            )

            return None


        if len(pairs) != 3:

            print(
                "❌ Match must contain exactly 3 pairs."
            )

            return None


        for pair in pairs:

            if not isinstance(
                pair,
                dict
            ):

                print(
                    "❌ Invalid match pair."
                )

                return None


            if not pair.get(
                "left"
            ) or not pair.get(
                "right"
            ):

                print(
                    "❌ Match pair is incomplete."
                )

                return None


        # =====================================================
        # CHOOSE VALIDATION
        # =====================================================

        choose_activity = activities[2]


        choose_options = choose_activity.get(
            "options"
        )


        if not isinstance(
            choose_options,
            list
        ) or len(choose_options) != 3:

            print(
                "❌ Choose must have exactly 3 options."
            )

            return None


        if choose_activity.get(
            "correct_answer"
        ) not in choose_options:

            print(
                "❌ Choose correct_answer "
                "must match an option."
            )

            return None


        # =====================================================
        # GENERATE MAIN VOICE
        # =====================================================

        main_audio_filename = (
            f"day_{day_number}_voice.wav"
        )


        try:

            generate_voice(

                learning_data[
                    "voice_text"
                ],

                main_audio_filename

            )


            learning_data[
                "audio_path"
            ] = (
                f"generated_audio/"
                f"{main_audio_filename}"
            )


        except Exception as e:

            print()
            print(
                "❌ Main voice generation failed:"
            )

            print(e)

            return None


        # =====================================================
        # GENERATE REVIEW VOICE
        # =====================================================

        review_audio_filename = (
            f"day_{day_number}_review.wav"
        )


        try:

            generate_voice(

                learning_data[
                    "review_voice"
                ],

                review_audio_filename

            )


            learning_data[
                "review_audio_path"
            ] = (
                f"generated_audio/"
                f"{review_audio_filename}"
            )


        except Exception as e:

            print()
            print(
                "❌ Review voice generation failed:"
            )

            print(e)

            return None


        # =====================================================
        # FINAL SUCCESS
        # =====================================================

        print()
        print(
            "🎉 Learning + Voice generated successfully!"
        )


        return learning_data


    # =========================================================
    # JSON ERROR
    # =========================================================

    except json.JSONDecodeError as e:

        print()
        print(
            "❌ AI returned invalid JSON."
        )

        print(
            "JSON Error:",
            e
        )

        print()
        print(
            "AI Output:"
        )

        print(content)

        return None


    # =========================================================
    # GENERAL ERROR
    # =========================================================

    except Exception as e:

        print()
        print(
            "❌ Ollama Error:"
        )

        print(e)

        return None