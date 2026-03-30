from fastapi import APIRouter, HTTPException, Request, Body
from fastapi.responses import HTMLResponse
from app.core.logger import logger
from app.core.config import templates
from app.api.schemas import GenerateRequest, GenerateResponse
from app.services.ai_service import generate_with_ollama
from app.db.redis_client import save_message, get_history, get_cached_response, set_cached_response

router = APIRouter(tags=["Code Generation"])


@router.post("/code/{item_id}")
async def create_code(item_id: int):
    if item_id < 10:
        logger.warning(f"Invalid item_id: {item_id}")
        raise HTTPException(status_code=400, detail="Invalid item_id")
    logger.info(f"Creating code for item_id: {item_id}")
    return {"item_id": item_id, "code": f"CODE-{item_id}"}

@router.post("/adding/{num1}/{num2}")
async def add_numbers(num1: int, num2: int):
    if num1 and num2:
        result = num1 + num2
        logger.info(f"Adding numbers: {num1} + {num2} = {result}")
        return {"num1": num1, "num2": num2, "result": result}
    else:
        logger.warning(f"Invalid input: num1={num1}, num2={num2}")
        raise HTTPException(status_code=400, detail="Invalid input")
    
@router.post("/subtract/{num1}/to/{num2}")
async def subtract_numbers(num1: int, num2: int):
    if num1 and num2:
        result = num1 - num2
        logger.info(f"Subtracting numbers: {num1} - {num2} = {result}")
        return {"num1": num1, "num2": num2, "result": result}
    else:
        logger.warning(f"Invalid input: num1={num1}, num2={num2}")
        raise HTTPException(status_code=400, detail="Invalid input")
    
@router.post("/generate", response_model=GenerateResponse)
async def generate_text(data: GenerateRequest):
    save_message(data.session_id, f"User: {data.prompt}")
    cached = get_cached_response(data.session_id, data.prompt)
    if cached:
        logger.info(f"Cache hit for prompt: {data.prompt}")
        return GenerateResponse(
            response=cached, 
            history=get_history(data.session_id)
        )
    history = get_history(data.session_id)[-10:]
    full_prompt = "\n".join(history) + "\nAI:"
    ai_output = await generate_with_ollama(full_prompt)
    save_message(data.session_id, f"AI: {ai_output}")
    set_cached_response(data.session_id, data.prompt, ai_output)
    logger.info(f"Generated text for prompt: {data.prompt}")
    # history = get_history(data.session_id)
    return GenerateResponse(
        response=ai_output,
        history=history
    )

@router.get("/history/{session_id}")
async def get_chat_history(session_id: str):
    history = get_history(session_id)
    logger.info("Retrieved chat history")
    return {"history": history}