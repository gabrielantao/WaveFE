from pathlib import Path
import os

# general paths of the program
PATH_ROOT = Path(os.environ["PIXI_PACKAGE_ROOT"])
PATH_APPLICATION = PATH_ROOT / Path(os.environ["WAVE_PATH_APPLICATION"])
PATH_SIMULATOR = PATH_ROOT / Path(os.environ["WAVE_PATH_SIMULATOR"])

# validators version for each *.toml input file
CONDITIONS_TOML_VERSION = 1
SIMULATION_TOML_VERSION = 1
VALIDATION_TOML_VERSION = 1

# default name for some files
DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
SIMULATION_FILENAME = "simulation.toml"

# paths for the simulator
SIMULATION_CACHE_PATH = Path("cache")
SIMULATION_LOG_PATH = SIMULATION_CACHE_PATH / Path("log")
SIMULATION_RESULT_PATH = SIMULATION_CACHE_PATH / Path("result")
SIMULATION_TEMP_PATH = SIMULATION_CACHE_PATH / Path("temp")
