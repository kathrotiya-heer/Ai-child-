import ollama
import json
import os
import sys
import subprocess


# =========================================================
# PIPER TTS CONFIGURATION
# =========================================================

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_DIR = os.path.dirname(BACKEND_DIR)

VOICE_MODEL = os.path.join(
    PROJECT_DIR,
    "hi_IN-priyamvada-medium.onnx"
)

AUDIO_DIR = os.path.join(
    PROJECT_DIR,
    "generated_audio"
)


# =========================================================
# GENERATE VOICE USING PIPER
# =========================================================

def generate_voice(text, filename):

    if not text or not text.strip():
        raise ValueError("Voice text is empty")

    if not os.path.exists(VOICE_MODEL):
        raise FileNotFoundError(
            f"Piper voice model not found:\n{VOICE_MODEL}"
        )

    # Create generated_audio folder
    os.makedirs(
        AUDIO_DIR,
        exist_ok=True
    )

    # Full output path
    output_path = os.path.join(
        AUDIO_DIR,
        filename
    )

    # IMPORTANT:
    # Use current virtual environment Python
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

    print("\n🎙️ Generating voice...")
    print("Python:", python_executable)
    print("Voice model:", VOICE_MODEL)
    print("Output:", output_path)

    try:

        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )

    except Exception as e:

        print("❌ Could not start Piper:")
        print(e)

        raise


    # =====================================================
    # CHECK PIPER RESULT
    # =====================================================

    if result.returncode != 0:

        print("\n❌ Piper TTS failed!")

        if result.stderr:
            print("\nPiper Error:")
            print(result.stderr)

        raise RuntimeError(
            f"Piper TTS failed:\n{result.stderr}"
        )


    # =====================================================
    # CHECK OUTPUT FILE
    # =====================================================

    if not os.path.exists(output_path):

        raise RuntimeError(
            "Piper completed but audio file was not created."
        )


    # =====================================================
    # SUCCESS
    # =====================================================

    print(
        f"✅ Voice generated successfully: "
        f"{output_path}"
    )

    return output_path


# =========================================================
# VALIDATE LEARNING DATA
# =========================================================

def validate_learning_data(data):

    # -----------------------------------------------------
    # Required main fields
    # -----------------------------------------------------

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
        "reward_stars",
    ]

    for field in required_fields:

        if field not in data:

            print(
                f"❌ Missing field: {field}"
            )

            return False


    # -----------------------------------------------------
    # Basic type validation
    # -----------------------------------------------------

    if not isinstance(data["day"], int):

        print(
            "❌ day must be an integer"
        )

        return False


    if not isinstance(
        data["duration_minutes"],
        int
    ):

        print(
            "❌ duration_minutes must be an integer"
        )

        return False


    if not isinstance(
        data["reward_stars"],
        int
    ):

        print(
            "❌ reward_stars must be an integer"
        )

        return False


    # -----------------------------------------------------
    # Visual ideas
    # -----------------------------------------------------

    visual_ideas = data["visual_ideas"]

    if not isinstance(
        visual_ideas,
        list
    ):

        print(
            "❌ visual_ideas must be a list"
        )

        return False


    if len(visual_ideas) != 3:

        print(
            "❌ Exactly 3 visual ideas required"
        )

        return False


    for visual in visual_ideas:

        if not isinstance(
            visual,
            str
        ):

            print(
                "❌ Visual idea must be text"
            )

            return False


        if not visual.strip():

            print(
                "❌ Empty visual idea"
            )

            return False


    # -----------------------------------------------------
    # Activities
    # -----------------------------------------------------

    activities = data["activities"]

    if not isinstance(
        activities,
        list
    ):

        print(
            "❌ activities must be a list"
        )

        return False


    if len(activities) != 3:

        print(
            "❌ Exactly 3 activities required"
        )

        return False


    # Required order

    expected_types = [
        "tap",
        "match",
        "choose",
    ]


    actual_types = [
        activity.get("type")
        for activity in activities
    ]


    if actual_types != expected_types:

        print(
            "❌ Activity types/order incorrect"
        )

        print(
            "Expected:",
            expected_types
        )

        print(
            "Received:",
            actual_types
        )

        return False


    # =====================================================
    # TAP ACTIVITY
    # =====================================================

    tap = activities[0]


    if not tap.get("title"):

        print(
            "❌ Tap title missing"
        )

        return False


    if not tap.get("instruction"):

        print(
            "❌ Tap instruction missing"
        )

        return False


    tap_options = tap.get(
        "options"
    )


    if not isinstance(
        tap_options,
        list
    ):

        print(
            "❌ Tap options must be a list"
        )

        return False


    if len(tap_options) < 3:

        print(
            "❌ Tap needs at least 3 options"
        )

        return False


    tap_answer = tap.get(
        "correct_answer"
    )


    if tap_answer not in tap_options:

        print(
            "❌ Tap correct answer is not inside options"
        )

        print(
            "Options:",
            tap_options
        )

        print(
            "Answer:",
            tap_answer
        )

        return False


    # =====================================================
    # MATCH ACTIVITY
    # =====================================================

    match = activities[1]


    if not match.get("title"):

        print(
            "❌ Match title missing"
        )

        return False


    if not match.get("instruction"):

        print(
            "❌ Match instruction missing"
        )

        return False


    pairs = match.get(
        "pairs"
    )


    if not isinstance(
        pairs,
        list
    ):

        print(
            "❌ Match pairs must be a list"
        )

        return False


    if len(pairs) != 3:

        print(
            "❌ Match needs exactly 3 pairs"
        )

        return False


    for pair in pairs:

        if not isinstance(
            pair,
            dict
        ):

            print(
                "❌ Invalid match pair"
            )

            return False


        if "left" not in pair:

            print(
                "❌ Match pair missing left"
            )

            return False


        if "right" not in pair:

            print(
                "❌ Match pair missing right"
            )

            return False


        if not pair["left"]:

            print(
                "❌ Empty left value"
            )

            return False


        if not pair["right"]:

            print(
                "❌ Empty right value"
            )

            return False


    # =====================================================
    # CHOOSE ACTIVITY
    # =====================================================

    choose = activities[2]


    if not choose.get("title"):

        print(
            "❌ Choose title missing"
        )

        return False


    if not choose.get("instruction"):

        print(
            "❌ Choose instruction missing"
        )

        return False


    choose_options = choose.get(
        "options"
    )


    if not isinstance(
        choose_options,
        list
    ):

        print(
            "❌ Choose options must be a list"
        )

        return False


    # Exactly 3 options

    if len(choose_options) != 3:

        print(
            "❌ Choose must have exactly 3 options"
        )

        return False


    choose_answer = choose.get(
        "correct_answer"
    )


    # IMPORTANT

    if choose_answer not in choose_options:

        print(
            "❌ Choose correct answer is not inside options"
        )

        print(
            "Options:",
            choose_options
        )

        print(
            "Answer:",
            choose_answer
        )

        return False


    # -----------------------------------------------------
    # Estimated minutes
    # -----------------------------------------------------

    for activity in activities:

        if "estimated_minutes" not in activity:

            print(
                "❌ estimated_minutes missing"
            )

            return False


        if not isinstance(
            activity["estimated_minutes"],
            int
        ):

            print(
                "❌ estimated_minutes must be integer"
            )

            return False


    # -----------------------------------------------------
    # Success
    # -----------------------------------------------------

    print(
        "✅ Learning data validation passed!"
    )

    return True


# =========================================================
# CREATE PROMPT
# =========================================================

def create_prompt(
    day_number,
    category,
    skill,
    age_group="5-7"
):

    prompt = f"""

You are an expert AI educational content creator.

Create ONE daily learning session for children aged {age_group}.

Day:
{day_number}

Category:
{category}

Skill:
{skill}


=========================================================
CHILD PROFILE
=========================================================

The child is between 5 and 7 years old.

The child may not be able to read properly.

Therefore the lesson MUST be:

- voice-first
- visual-first
- simple
- playful
- interactive
- short instructions
- real-life based

Do NOT depend on reading.

Do NOT ask the child to type answers.

Do NOT use difficult words.


=========================================================
SESSION
=========================================================

The complete session should take approximately 30 minutes.

Create:

1. Introduction
2. Voice explanation
3. Three visual ideas
4. Three interactive activities
5. Real-life activity
6. Review voice
7. Reward stars


=========================================================
VISUAL RULES
=========================================================

Create exactly 3 visual ideas.

Each visual idea should be something that can later become:

- an illustration
- an image
- a simple animation
- a visual scene

Do NOT make visual ideas that depend on reading text.


=========================================================
VOICE RULES
=========================================================

voice_text must sound like a friendly teacher talking to a child.

Use short sentences.

Use encouraging language.

review_voice should congratulate the child and briefly review the lesson.


=========================================================
ACTIVITY RULES
=========================================================

Create EXACTLY 3 activities.

Activity order MUST be:

1. tap
2. match
3. choose


=========================================================
TAP ACTIVITY
=========================================================

The type MUST be:

"tap"

Create a simple visual question.

The child chooses one correct option.

There MUST be at least 3 options.

VERY IMPORTANT:

correct_answer MUST EXACTLY MATCH one option.

Example:

"options": [
    "Toy box",
    "Bed",
    "Floor"
],

"correct_answer": "Toy box"


=========================================================
MATCH ACTIVITY
=========================================================

The type MUST be:

"match"

Create EXACTLY 3 meaningful pairs.

Each left item must logically match the right item.

Good examples:

Toy -> Toy Box

Book -> Bookshelf

Clothes -> Wardrobe


Bad examples:

Shirt -> Pants

Dog -> Banana

Car -> Book


Never create random pairs.

Do not use "picture" as the right value.

The pair should describe the actual relationship.


=========================================================
CHOOSE ACTIVITY
=========================================================

The type MUST be:

"choose"

Create EXACTLY 3 options.

Only ONE option should be correct.

VERY IMPORTANT:

correct_answer MUST EXACTLY MATCH one of the 3 options.

Example:

"options": [
    "Toy box",
    "Bed",
    "Floor"
],

"correct_answer": "Toy box"


NEVER create:

"options": [
    "Box"
],

"correct_answer": "Shelf"


=========================================================
SAFETY
=========================================================

Activities must be safe for young children.

Do not create dangerous activities.

Do not require:

- internet
- money
- personal phone
- dangerous objects
- cooking
- sharp objects
- electrical equipment


=========================================================
JSON RULES
=========================================================

Return ONLY valid JSON.

Do NOT use markdown.

Do NOT use:

```json

Do NOT add explanations.

Do NOT add text before JSON.

Do NOT add text after JSON.

Do NOT use trailing commas.


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

    return prompt


# =========================================================
# GENERATE LEARNING DAY
# =========================================================

def generate_learning_day(
    day_number,
    category,
    skill,
    age_group="5-7",
    max_retries=3
):

    prompt = create_prompt(
        day_number=day_number,
        category=category,
        skill=skill,
        age_group=age_group
    )


    for attempt in range(
        1,
        max_retries + 1
    ):

        print(
            f"\n🤖 Generating Day {day_number} "
            f"(Attempt {attempt}/{max_retries})..."
        )


        try:

            # =================================================
            # OLLAMA
            # =================================================

            response = ollama.chat(
                model="llama3.2:3b",

                # Force JSON response
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


            # -------------------------------------------------
            # Remove accidental markdown
            # -------------------------------------------------

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


            # -------------------------------------------------
            # Parse JSON
            # -------------------------------------------------

            data = json.loads(
                content
            )


            print(
                "✅ JSON parsed successfully!"
            )


            # -------------------------------------------------
            # Validate
            # -------------------------------------------------

            if validate_learning_data(
                data
            ):

                print(
                    f"✅ Day {day_number} "
                    f"generated successfully!"
                )


                # =================================================
                # GENERATE MAIN VOICE
                # =================================================

                try:

                    main_audio_filename = (
                        f"day_{day_number}_voice.wav"
                    )


                    generate_voice(
                        data["voice_text"],
                        main_audio_filename
                    )


                    data["audio_path"] = (
                        f"generated_audio/"
                        f"{main_audio_filename}"
                    )


                    print(
                        "🎙️ Main voice ready:",
                        data["audio_path"]
                    )


                except Exception as e:

                    print(
                        f"❌ Main voice generation failed: {e}"
                    )

                    return None


                # =================================================
                # GENERATE REVIEW VOICE
                # =================================================

                try:

                    review_audio_filename = (
                        f"day_{day_number}_review.wav"
                    )


                    generate_voice(
                        data["review_voice"],
                        review_audio_filename
                    )


                    data["review_audio_path"] = (
                        f"generated_audio/"
                        f"{review_audio_filename}"
                    )


                    print(
                        "🎙️ Review voice ready:",
                        data["review_audio_path"]
                    )


                except Exception as e:

                    print(
                        f"❌ Review voice generation failed: {e}"
                    )

                    return None


                # =================================================
                # FINAL SUCCESS
                # =================================================

                print(
                    f"\n🎉 Day {day_number} "
                    f"with voice generated successfully!"
                )


                return data


            else:

                print(
                    f"⚠️ Day {day_number} "
                    f"failed validation."
                )


        except json.JSONDecodeError as e:

            print(
                "❌ Invalid JSON returned by AI."
            )

            print(
                "JSON Error:",
                e
            )


        except Exception as e:

            print(
                "❌ Ollama Error:"
            )

            print(e)


    # ---------------------------------------------------------
    # All attempts failed
    # ---------------------------------------------------------

    print(
        f"\n❌ Failed to generate valid "
        f"Day {day_number}."
    )


    return None