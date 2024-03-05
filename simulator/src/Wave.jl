module Wave

using ArgParse
using TOML
using HDF5
#using ProgressMeter


include("models/register.jl")
include("validator.jl")

export run_simulation

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


"""Main function of the Wave simulator"""
function run_simulation()
    parsed_args = parse_commandline()
    folder = parsed_args["folder"]

    # input all the relevant data to build the model 
    cache_filepath = joinpath(folder, CACHE_PATH)
    input_data = h5open(joinpath(cache_filepath, SIMULATION_MESH_FILENAME), "r")
    simulation_data = TOML.parsefile(joinpath(cache_filepath, SIMULATION_INPUT_FILENAME))
    domain_conditions_data = TOML.parsefile(joinpath(cache_filepath, DOMAIN_CONDITIONS_FILENAME))
    
    # do the logical validations for the inputs
    # TODO [general performance improvements] 
    ## maybe move these validations for the model file (if it depends on model... think about it)
    validate_simulation_data(simulation_data)
    validate_domain_conditions_data(domain_conditions_data)

    # get the model based in the simulation model defined in input file
    model = build_model(folder, input_data, simulation_data, domain_conditions_data)
  
    # write the output values for the initial time step
    write_result_data(model.output_handler, model.unknowns_handler, 0)

    total_step_limits = simulation_data["simulation"]["steps_limit"]
    if parsed_args["show-progress"]
        # TODO: wrap here the main loop with the progress
        # progress = ProgressUnknown("running... ", spinner=true, color = :white)  
        main_loop(model, total_step_limits)
    else
        main_loop(model, total_step_limits)
    end
end

"""The main loop of the simulation"""
function main_loop(model, total_step_limits)
    # TODO: write elapsed time and total steps elapsed (and log it)
    elapsed_time = 0.0
    success = false
    # elapsed_time = @elapsed begin   
        # run main loop 
        for timestep_counter in range(1, total_step_limits) 
            # ProgressMeter.next!(progress)
            
            run_iteration(model)

            # stop simulation loop if converged
            if all(values(model.unknowns_handler.converged))
                # force to write the result at last time step
                write_result_data(model.output_handler, model.unknowns_handler, timestep_counter)
                success = true
                break
            end
            write_result_data(model.output_handler, model.unknowns_handler, timestep_counter)
        end
    # end # elapsed macro

    write_additional_data(model.output_handler, success, timestep_counter, elapsed_time)
    close_files(model.output_handler)
    return timestep_counter
end

end # module
