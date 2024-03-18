module WaveValidationTests
using ReTest
using ReferenceTests
using ArgParse
using HDF5
using DelimitedFiles

const WAVE_SIMULATOR_TEST_PATH = joinpath(ENV["PIXI_PROJECT_ROOT"], "simulator", "test")
const WAVE_SIMULATOR_TEST_CASE_PATH = joinpath(WAVE_SIMULATOR_TEST_PATH, "cases")


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
        "--log-level", "-L"    
            help = "define if log level" 
            arg_type = Int
            default = 1
        "test-name"
            help = "test or testset name to be run"
    end

    return parse_args(s)
end


const PARSED_ARGS = parse_commandline()

include("../src/core/wave_core.jl")
using .WaveCore: run_simulation

# get the registered models in order to get their names
include("../src/models/register.jl")

# utilities to run the validation cases
include("cases/utils.jl")

# the list of registered cases
include("cases/test_validation.jl")

"""This function is used to run case tests from the shell"""
function run_cases()
    if PARSED_ARGS["run-all"]
        retest(
            WaveValidationTests, 
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

end # module

WaveValidationTests.run_cases()
