import redis

redis_client = redis.Redis(
    host='localhost',
    port=6379,
    db=0,
    decode_responses=True
)

redis_client.set('test_key', 'Hello, Redis!')
print(redis_client.get('test_key'))  # Output: Hello, Redis!

def save_message(session_id: str, message: str):
    redis_client.rpush(f"chat_history:{session_id}", message)

def get_history(session_id: str):
    return redis_client.lrange(f"chat_history:{session_id}", 0, -1)

def get_cached_response(session_id: str, prompt: str):
    return redis_client.get(f"cache:{session_id}:{prompt}")

def set_cached_response(session_id: str, prompt: str, response: str):
    redis_client.set(f"cache:{session_id}:{prompt}", response)