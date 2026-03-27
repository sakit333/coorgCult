import requests
from app.core.config import settings

async def generate_with_ollama(prompt: str):
    response = requests.post(
        f"{settings.OLLAMA_URL}/api/generate",
        json={
            "model": "deepseek-coder",
            "prompt": prompt,
            "stream": False,
        }
    )
    return response.json().get("response", "")