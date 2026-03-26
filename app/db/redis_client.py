import redis

redis_client = redis.Redis(
    host='localhost',
    port=6379,
    db=0,
    decode_responses=True
)

redis_client.set('test_key', 'Hello, Redis!')
print(redis_client.get('test_key'))  # Output: Hello, Redis!

def save_message(message: str):
    redis_client.rpush("chat_history", message)

def get_history():
    return redis_client.lrange("chat_history", 0, -1)