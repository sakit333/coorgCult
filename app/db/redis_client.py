import redis
from app.core.config import settings

redis_client = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=0,
    decode_responses=True
)

redis_client.set('test_key', 'Hello, Redis!')
print(redis_client.get('test_key'))  # Output: Hello, Redis!

def save_message(session_id: str, message: str):
    key = f"chat_history:{session_id}"
    redis_client.rpush(key, message)
    redis_client.expire(key, 1800)  # Set expiration for chat history (30 minutes)

def delete_history(session_id: str):
    redis_client.delete(f"chat_history:{session_id}")

def get_history(session_id: str):
    return redis_client.lrange(f"chat_history:{session_id}", 0, -1)

def get_cached_response(session_id: str, prompt: str):
    return redis_client.get(f"cache:{session_id}:{prompt}")

def set_cached_response(session_id: str, prompt: str, response: str):
    redis_client.setex(
        f"cache:{session_id}:{prompt}", 
        600,  # Cache expires in 10 minutes
        response
    )