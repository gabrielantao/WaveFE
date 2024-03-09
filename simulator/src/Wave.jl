module Wave
using ArgParse


include("core/wave_core.jl")
using .WaveCore: run_simulation


"""Extract the values from terminal"""
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--show-progress", "-s"
            help = "define if it should print progress in the terminal" 
            action = :store_true
        "--log-level", "-L"    
            help = "define if log level" 
            arg_type = Int
            default = 1
        "folder"
            help = "path folder for simulation files"
            required = true
    end

    return parse_args(s)
end


# call the main function of the simulator
main() = run_simulation(parse_commandline())

end # module
