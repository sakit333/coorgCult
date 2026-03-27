from pydantic import BaseModel

class GenerateRequest(BaseModel):
    prompt: str
    session_id: str

class GenerateResponse(BaseModel):
    response: str
    history: list[str] = []