from fastapi.templating import Jinja2Templates
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Configuration settings
class Settings:
    # Redis settings
    REDIS_HOST = os.getenv("REDIS_HOST")
    REDIS_PORT = int(os.getenv("REDIS_PORT"))

    # Ollama settings
    OLLAMA_URL = os.getenv("OLLAMA_URL")

settings = Settings()

# Initialize templates
templates = Jinja2Templates(directory="app/templates")

