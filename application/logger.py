import logging
from application.constants import WAVE_PATH_APPLICATION


class ApplicationLogger:
    """Basic logger for the application"""

    def __init__(self):
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(message)s",
            datefmt="%d-%b-%y %H:%M:%S",
        )
        # application general logger
        logging_level = logging.INFO
        self.log = logging.getLogger("application")
        logger_handler = logging.FileHandler(
            WAVE_PATH_APPLICATION / "logs" / "application.log", mode="w"
        )
        self.log.addHandler(logger_handler)
        self.log.setLevel(logging_level)


logger = ApplicationLogger()
