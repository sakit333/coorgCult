from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.modules.auth.schemas import UserSignup, UserSignupResponse, UserLogin, UserLoginResponse
from app.modules.auth.service import signup_user, user_login

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
        id=new_user.id
    )

@router.post("/login", response_model=UserLoginResponse)
async def login(user: UserLogin, db: AsyncSession = Depends(get_db)):
    user = await user_login(
        db=db,
        username=user.username,
        password=user.password
    )
    return UserLoginResponse(
        access_token=user["access_token"],
        token_type=user["token_type"]
    )