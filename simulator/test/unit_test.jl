include("all_tests.jl")
using ArgParse

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
            help = "show data about the listed tests"
            arg_type = Int
            default = 1
        # TODO: put option to regenerate results in ReferenceTests context
        # TODO: think if it should be a list
        "test-name"
            help = "test or testset name to be run"
    end

    return parse_args(s)
end



"""This function is used to run unit tests from the shell"""
function run_unit_test()
    parsed_args = parse_commandline()
    if parsed_args["run-all"]
        run_all_unit_tests(
            parsed_args["run-dry"],
            parsed_args["verbose"]
        )
    else 
        retest(
            parsed_args["test-name"], 
            dry=parsed_args["run-dry"],
            verbose=parsed_args["verbose"])
    end
end


run_unit_test()