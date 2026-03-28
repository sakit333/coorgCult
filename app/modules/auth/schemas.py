from pydantic import BaseModel

class UserSignup(BaseModel):
    username: str
    email: str
    password: str

class UserSignupResponse(BaseModel):
    id: int
    username: str
