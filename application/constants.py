from pathlib import Path

# general paths
PATH_WAVE_ROOT = Path(__file__).resolve().parents[1]
PATH_CASES = PATH_WAVE_ROOT / Path("cases")
PATH_SIMULATOR = PATH_WAVE_ROOT / Path("core")
PATH_LEGACY = PATH_WAVE_ROOT / Path("legacy")
PATH_MESH = PATH_WAVE_ROOT / Path("mesh")

# backend test paths
PATH_BACKEND_TEST_DATA = PATH_WAVE_ROOT / "application" / "tests" / "data"

# test paths to core
PATH_TEST_SIMULATOR = PATH_SIMULATOR / Path("test")
PATH_TEST_DATA = PATH_TEST_SIMULATOR / Path("data")
PATH_TEST_TEMP = PATH_TEST_SIMULATOR / Path("temp")
PATH_TEST_UNIT = PATH_TEST_SIMULATOR / Path("test_unit")

# PATH_LEGACY_PROGRAM
PATH_LEGACY_BUILD = PATH_LEGACY / Path("build")
PATH_LEGACY_CASES = PATH_LEGACY / Path("cases")


# default name for some files
DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
SIMULATION_FILENAME = "simulation.toml"

# validators version for each *.toml input file
CONDITIONS_TOML_VERSION = 1
SIMULATION_TOML_VERSION = 1
VALIDATION_TOML_VERSION = 1
