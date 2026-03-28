from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException
from app.modules.auth.models import User
from app.core.security import create_access_token

async def signup_user(db: AsyncSession, username: str, email: str, password: str):
    
    result = await db.execute(
        select(User).where(
            (User.username == username) | (User.email == email)
        )
    )
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(status_code=400, detail="Username or email already exists")

    new_user = User(
        username=username,
        email=email,
        password=password  # ⚠️ later we’ll hash this
    )

    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return new_user

async def user_login(db: AsyncSession, username: str, password: str):
    result = await db.execute(select(User).where(User.username == username))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.password != password:  # ⚠️ later we’ll hash and compare hashes
        raise HTTPException(status_code=400, detail="Invalid password")
    return {
        "access_token": create_access_token(data={"sub": user.username}),
        "token_type": "bearer",
    }