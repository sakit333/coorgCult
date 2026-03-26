import logging
import os

os.makedirs("logs", exist_ok=True)

#  create logger
logger = logging.getLogger("app_logger")
logger.setLevel(logging.INFO)

#  create formatter
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# file handler
file_handler = logging.FileHandler("logs/app.log")
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(formatter)

#  console handler
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

#  attach handlers to logger
if not logger.hasHandlers():
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)