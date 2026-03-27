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

    # PostgreSQL settings
    POSTGRES_HOST = os.getenv("POSTGRES_HOST")
    POSTGRES_PORT = int(os.getenv("POSTGRES_PORT"))
    POSTGRES_DB = os.getenv("POSTGRES_DB")
    POSTGRES_USER = os.getenv("POSTGRES_USER")
    POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")

settings = Settings()

# Initialize templates
templates = Jinja2Templates(directory="app/templates")

