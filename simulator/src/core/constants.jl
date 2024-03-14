# file paths
const CACHE_PATH = "cache"
const RESULT_PATH = "result"
const REFERENCE_PATH = "reference"

# input files names
const DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
const SIMULATION_INPUT_FILENAME = "simulation.toml"
const SIMULATION_MESH_FILENAME = "input.hdf5"

# output file names
const SIMULATOR_LOG_FILENAME = "simulation.log"
const RESULT_FILENAME = "result.hdf5"
const DEBUG_FILENAME = "debug.hdf5"

# versions of output files
const RESULT_FILE_CURRENT_VERSION = "1.0"
const DEBUG_FILE_CURRENT_VERSION = "1.0"


export CACHE_PATH, RESULT_PATH
export DOMAIN_CONDITIONS_FILENAME, SIMULATION_INPUT_FILENAME, SIMULATION_MESH_FILENAME
export SIMULATOR_LOG_FILENAME, RESULT_FILENAME, DEBUG_FILENAME

export RESULT_FILE_CURRENT_VERSION, DEBUG_FILE_CURRENT_VERSION