from ai_generator import generate_learning_day
import json


learning = generate_learning_day(
    day_number=1,
    category="At Home",
    skill="Organizing My Room"
)


if learning:

    print("\n✅ Learning generated successfully!\n")

    print(
        json.dumps(
            learning,
            indent=2,
            ensure_ascii=False
        )
    )

else:

    print("\n❌ Learning generation failed.")