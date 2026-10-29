from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import ParentUser
from security import decode_access_token, oauth2_scheme


def get_current_parent(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> ParentUser:

    try:
        parent_id = decode_access_token(token)

    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired login session",
            headers={
                "WWW-Authenticate": "Bearer"
            },
        )

    parent = (
        db.query(ParentUser)
        .filter(ParentUser.id == parent_id)
        .first()
    )

    if parent is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User no longer exists",
            headers={
                "WWW-Authenticate": "Bearer"
            },
        )

    return parent