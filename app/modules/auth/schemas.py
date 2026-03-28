from pydantic import BaseModel, EmailStr, Field
from uuid import UUID

class UserSignup(BaseModel):
    username: str
    email: EmailStr
    password: str = Field(min_length=8, max_length=50)  # Enforce minimum password length

class UserSignupResponse(BaseModel):
    id: UUID

    class Config:
        from_attributes = True 

class UserLogin(BaseModel):
    username: str
    password: str

class UserLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"