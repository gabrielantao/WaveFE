# file paths
const CACHE_PATH = "cache"
const REFERENCE_PATH = "reference"
const RESULT_PATH = "result"

# input and cached file names
const DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
const SIMULATION_FILENAME = "simulation.toml"
const CACHED_DATA_FILENAME = "cached_data.toml"

# output file names
const LOG_FILENAME = "simulation.log"
const RESULT_FILENAME = "result.hdf5"
const DEBUG_FILENAME = "debug.hdf5"

# versions of output files
const RESULT_FILE_CURRENT_VERSION = "1.0"
const DEBUG_FILE_CURRENT_VERSION = "1.0"


export CACHE_PATH, REFERENCE_PATH, RESULT_PATH, CACHED_DATA_FILENAME
export DOMAIN_CONDITIONS_FILENAME, SIMULATION_FILENAME
export LOG_FILENAME, RESULT_FILENAME, DEBUG_FILENAME

export RESULT_FILE_CURRENT_VERSION, DEBUG_FILE_CURRENT_VERSION