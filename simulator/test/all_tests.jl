module WaveUnitTests
using Wave

using ReTest
using TOML
using HDF5
using ReferenceTests

include("utils.jl")

const WAVE_SIMULATOR_TEST_PATH = joinpath(
    ENV["PIXI_PACKAGE_ROOT"], "simulator", "test"
)

const WAVE_SIMULATOR_TEST_DATA_PATH = joinpath(
    WAVE_SIMULATOR_TEST_PATH, "data"
)


# unit test list
include("test_mesh.jl")
# TODO: include other files with tests here 

end # module


using ReTest

function run_all_unit_tests(dry=false, verbose=1)    
    retest(WaveUnitTests, dry=dry, verbose=verbose)
    # TODO: include other modules here
end
