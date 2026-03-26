from fastapi import APIRouter, HTTPException, Request, Body
from fastapi.responses import HTMLResponse
from app.core.logger import logger
from app.core.config import templates
from app.api.schemas import GenerateRequest, GenerateResponse

router = APIRouter(tags=["Code Generation"])

@router.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse(name="index.html", context={"request": request}, request=request)


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
    return GenerateResponse(response=f"Generated text based on prompt: {data.prompt}")