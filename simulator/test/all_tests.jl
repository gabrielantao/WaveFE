module WaveUnitTests
using ReTest
using TOML
using HDF5
using ReferenceTests


using Wave


const WAVE_SIMULATOR_TEST_PATH = joinpath(ENV["PIXI_PACKAGE_ROOT"], "simulator", "test")
const WAVE_SIMULATOR_TEST_DATA_PATH = joinpath(WAVE_SIMULATOR_TEST_PATH, "data")


include("utils.jl")
include("fixtures.jl")

# unit test list
include("test_input.jl")
include("test_nodes.jl")
include("test_segments.jl")
include("test_triangles.jl")
include("test_quadrilaterals.jl")
include("test_mesh.jl")


end # module


using ReTest

function run_all_unit_tests(dry=false, verbose=1)    
    retest(WaveUnitTests, dry=dry, verbose=verbose)
    # TODO: include other modules here
end
