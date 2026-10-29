import hashlib
import secrets

from datetime import datetime, timedelta, timezone

import jwt

from pwdlib import PasswordHash

from fastapi.security import OAuth2PasswordBearer


# =========================================================
# JWT SETTINGS
# =========================================================

SECRET_KEY = "CHANGE_THIS_TO_A_LONG_RANDOM_SECRET_IN_PRODUCTION"

ALGORITHM = "HS256"

ACCESS_TOKEN_MINUTES = 60 * 24 * 30


# =========================================================
# PASSWORD HASHER
# =========================================================

password_hasher = PasswordHash.recommended()


# =========================================================
# OAUTH2
# IMPORTANT:
# Swagger Authorize will call /auth/token
# =========================================================

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/token"
)


# =========================================================
# PASSWORD / PIN HASH
# =========================================================

def hash_password(value: str) -> str:
    return password_hasher.hash(value)


def verify_password(
    value: str,
    hashed: str,
) -> bool:
    return password_hasher.verify(
        value,
        hashed,
    )


# =========================================================
# CREATE ACCESS TOKEN
# =========================================================

def create_access_token(
    parent_id: int,
) -> str:

    now = datetime.now(timezone.utc)

    payload = {
        "sub": str(parent_id),
        "type": "access",
        "iat": now,
        "exp": (
            now
            + timedelta(
                minutes=ACCESS_TOKEN_MINUTES
            )
        ),
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM,
    )


# =========================================================
# DECODE ACCESS TOKEN
# =========================================================

def decode_access_token(
    token: str,
) -> int:

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )

        if payload.get("type") != "access":
            raise ValueError()

        return int(
            payload["sub"]
        )

    except Exception as exc:
        raise ValueError(
            "Invalid or expired token"
        ) from exc


# =========================================================
# RESET TOKEN
# =========================================================

def create_reset_token() -> tuple[str, str]:

    raw = secrets.token_urlsafe(32)

    hashed = hashlib.sha256(
        raw.encode()
    ).hexdigest()

    return raw, hashed


def hash_reset_token(
    raw: str,
) -> str:

    return hashlib.sha256(
        raw.encode()
    ).hexdigest()