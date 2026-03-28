from pydantic import BaseModel

class UserSignup(BaseModel):
    username: str
    email: str
    password: str

class UserSignupResponse(BaseModel):
    id: int
    username: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"