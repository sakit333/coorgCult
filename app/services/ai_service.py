import requests

async def generate_with_ollama(prompt: str):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={
            "model": "deepseek-coder",
            "prompt": prompt,
            "stream": False,
        }
    )
    return response.json().get("response", "")