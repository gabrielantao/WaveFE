module WaveUnitTests
using ReTest
using TOML
using HDF5
using ReferenceTests
using ArgParse
using DelimitedFiles

using SparseArrays
using LinearAlgebra: dot
using Statistics: mean

include("../src/core/wave_core.jl")
using .WaveCore

# import the equations of semi-implicit model to be used to test the assembler
# TODO [implement model with heat transfer]
## maybe this should be tested in another module (for the models or tested only in validation tests)
include("../src/models/semi_implicit/header.jl")
include("../src/models/semi_implicit/equations/equation_one.jl")
include("../src/models/semi_implicit/equations/equation_two.jl")
include("../src/models/semi_implicit/equations/equation_three.jl")
include("../src/core/global_assembling.jl")

const WAVE_SIMULATOR_TEST_PATH = joinpath(ENV["PIXI_PACKAGE_ROOT"], "simulator", "test")
const WAVE_SIMULATOR_TEST_DATA_PATH = joinpath(WAVE_SIMULATOR_TEST_PATH, "data")


"""The argument parser to run the tests from shell"""
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--run-all", "-a"
            help = "run all unit tests"
            action = :store_true
        "--run-dry", "-d"
            help = "show data about the listed tests"
            action = :store_true
        "--verbose", "-v"
            help = "level of verbosity of printed tests"
            arg_type = Int
            default = 1
        "--regenerate-result", "-r" 
            help = "force regenerate the reference test results"
            action = :store_true
        "test-name"
            help = "test or testset name to be run"
    end

    return parse_args(s)
end


const PARSED_ARGS = parse_commandline()


"""This function is used to run unit tests from the shell"""
function run_unit_test()
    if PARSED_ARGS["run-all"]
        retest(
            WaveUnitTests, 
            dry=PARSED_ARGS["run-dry"], 
            verbose=PARSED_ARGS["verbose"]
        )
    else 
        retest(
            PARSED_ARGS["test-name"], 
            dry=PARSED_ARGS["run-dry"],
            verbose=PARSED_ARGS["verbose"]
        )
    end
end

# basic data for the unit tests
include("utils.jl")
include("fixtures.jl")

# unit test list
include("test_input.jl")
include("test_nodes.jl")
include("test_segments.jl")
include("test_triangles.jl")
include("test_quadrilaterals.jl")
include("test_mesh.jl")
include("test_domain_conditions.jl")
include("test_unknowns_handler.jl")
include("test_solver.jl")
include("test_global_assembling.jl")
include("test_output.jl")

# model specific elemental assemblers
include("models/test_semi_implicit.jl")

end # module

WaveUnitTests.run_unit_test()
