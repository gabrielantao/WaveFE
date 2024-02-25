module Wave

# TODO: check if it's needed here ...
#using ProgressMeter
using TOML
using HDF5
using ArgParse

# get all the models available
include("constants.jl")
include("models/register.jl")
include("validator.jl")


function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "folder"
            help = "path folder for simulation files"
            required = true
    end

    return parse_args(s)
end

# TODO: remove this, this function is just for test
# function smoke()
#     # parse args from comand line
#     parsed_args = parse_commandline()
#     folder = parsed_args["folder"]
    
#     # input all the relevant data to build the model 
#     cache_filepath = joinpath(folder, CACHE_FILEPATH)
#     input_data = h5open(joinpath(cache_filepath, SIMULATION_MESH_FILENAME), "r")
#     simulation_data = TOML.parsefile(joinpath(cache_filepath, SIMULATION_INPUT_FILENAME))
#     domain_conditions_data = TOML.parsefile(joinpath(cache_filepath, DOMAIN_CONDITIONS_FILENAME))
    
#     # do the logical validations for the inputs
#     validate_simulation_data(simulation_data)
#     validate_domain_conditions_data(domain_conditions_data)
#    # println(folder)
#     #println(ENV["JULIA_LOAD_PATH"])
# end


function run_simulator()
    # parse args from comand line
    parsed_args = parse_commandline()
    folder = parsed_args["folder"]

    
    # input all the relevant data to build the model 
    cache_filepath = joinpath(folder, CACHE_FILEPATH)
    input_data = h5open(joinpath(cache_filepath, SIMULATION_MESH_FILENAME), "r")
    simulation_data = TOML.parsefile(joinpath(cache_filepath, SIMULATION_INPUT_FILENAME))
    domain_conditions_data = TOML.parsefile(joinpath(cache_filepath, DOMAIN_CONDITIONS_FILENAME))
    
    # do the logical validations for the inputs
    validate_simulation_data(simulation_data)
    validate_domain_conditions_data(domain_conditions_data)

    # get the model based in the simulation model defined in input file
    model = build_model(input_data, simulation_data, domain_conditions_data)
    exit()
    # TODO: create output manager here
    # create output handler
    # output_manager = create_output_manager(
    #     folder,
    #     simulation_info["output"]["frequency"],
    #     simulation_info["output"]["save_result"],
    #     simulation_info["output"]["save_numeric"],
    #     simulation_info["output"]["save_debug"]
    # )

    total_step_limits = simulation_data["simulation"]["steps_limit"]
    # progress = ProgressUnknown("running... ", spinner=true, color = :white)  
    # elapsed_time = @elapsed begin 
    
    # Run main loop 
    for timestep_counter in range(1, total_step_limits) 
        # ProgressMeter.next!(progress)
        
        run_iteration(model)

        # stop simulation loop if converged
        if all(values(model.unknowns_handler.converged))
            # TODO: output values here
            break
        end
        # TODO: output values here
    end

    #     ProgressMeter.finish!(progress)
    # end # elapsed time macro
    # TODO: write elapsed time and total steps elapsed
    # TODO: close the output file
end


##############################
### RUN THE WAVE SIMULATOR ###
##############################
run_simulator()

end # end module
