from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.modules.auth.schemas import UserSignup, UserSignupResponse
from app.modules.auth.service import signup_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/signup", response_model=UserSignupResponse)
async def signup(user: UserSignup, db: AsyncSession = Depends(get_db)):
    
    new_user = await signup_user(
        db=db,
        username=user.username,
        email=user.email,
        password=user.password
    )

    return UserSignupResponse(
        id=new_user.id,
        username=new_user.username,
        email=new_user.email
    )