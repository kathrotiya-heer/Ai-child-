import os
import sys
import subprocess


# =========================================================
# PROJECT PATHS
# =========================================================

# backend folder
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))

# Project root
PROJECT_DIR = os.path.dirname(BACKEND_DIR)


# =========================================================
# PIPER VOICE MODEL
# =========================================================

VOICE_MODEL = os.path.join(
    PROJECT_DIR,
    "hi_IN-priyamvada-medium.onnx"
)


# =========================================================
# GENERATED AUDIO FOLDER
# =========================================================

AUDIO_DIR = os.path.join(
    PROJECT_DIR,
    "generated_audio"
)


# =========================================================
# GENERATE VOICE
# =========================================================

def generate_voice(text, filename="test_learning.wav"):
    """
    Convert text into speech using local Piper TTS.

    Parameters:
        text     : Text that should be converted to speech
        filename : Output audio filename

    Returns:
        Full path of generated WAV file
    """

    # -----------------------------------------------------
    # Check voice text
    # -----------------------------------------------------

    if not text or not text.strip():
        raise ValueError("Voice text is empty")


    # -----------------------------------------------------
    # Check Piper model
    # -----------------------------------------------------

    if not os.path.exists(VOICE_MODEL):
        raise FileNotFoundError(
            f"Piper voice model not found:\n{VOICE_MODEL}"
        )


    # -----------------------------------------------------
    # Create audio directory
    # -----------------------------------------------------

    os.makedirs(
        AUDIO_DIR,
        exist_ok=True
    )


    # -----------------------------------------------------
    # Output path
    # -----------------------------------------------------

    output_path = os.path.join(
        AUDIO_DIR,
        filename
    )


    # -----------------------------------------------------
    # Use CURRENT VIRTUAL ENVIRONMENT Python
    # -----------------------------------------------------

    python_executable = sys.executable


    # -----------------------------------------------------
    # Piper command
    # -----------------------------------------------------

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


    # -----------------------------------------------------
    # Run Piper
    # -----------------------------------------------------

    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )


    # -----------------------------------------------------
    # Check Piper result
    # -----------------------------------------------------

    if result.returncode != 0:

        print("\n❌ Piper TTS failed!")

        if result.stderr:
            print("\nError:")
            print(result.stderr)

        raise RuntimeError(
            f"Piper TTS failed:\n{result.stderr}"
        )


    # -----------------------------------------------------
    # Check generated file
    # -----------------------------------------------------

    if not os.path.exists(output_path):

        raise RuntimeError(
            "Piper completed but audio file was not created."
        )


    # -----------------------------------------------------
    # Success
    # -----------------------------------------------------

    print("\n✅ Voice generated successfully!")
    print("🎵 Audio:", output_path)


    return output_path