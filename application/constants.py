from pathlib import Path

# general paths
PATH_WAVE_ROOT = Path(__file__).resolve().parents[1]
PATH_APPLICATION = PATH_WAVE_ROOT / Path("application")
PATH_SIMULATOR = PATH_WAVE_ROOT / Path("simulator")
PATH_CBS_MODELS = PATH_SIMULATOR / Path("cbs_models")

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
