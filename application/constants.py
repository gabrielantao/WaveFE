from pathlib import Path
import os


WAVE_PATH_ROOT = Path(__file__).parents[1].resolve()
WAVE_PATH_APPLICATION = WAVE_PATH_ROOT / Path("application")
WAVE_PATH_SIMULATOR = WAVE_PATH_ROOT / Path("core")

# validators version for each *.toml input file
CONDITIONS_TOML_VERSION = 1
SIMULATION_TOML_VERSION = 1
VALIDATION_TOML_VERSION = 1

# default name for some files
DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
SIMULATION_FILENAME = "simulation.toml"
SIMULATION_INPUT_DATA_FILENAME = "input.hdf5"

# paths for the simulator
SIMULATION_CACHE_PATH = Path("cache")
SIMULATION_LOG_PATH = SIMULATION_CACHE_PATH / Path("log")
SIMULATION_RESULT_PATH = SIMULATION_CACHE_PATH / Path("result")
SIMULATION_TEMP_PATH = SIMULATION_CACHE_PATH / Path("temp")
