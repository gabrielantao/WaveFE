module WaveCore

using TOML
using HDF5
#using ProgressMeter
using SparseArrays
using Preconditioners
using IterativeSolvers

# export the main function of the wave core
export run_simulation


include("constants.jl")
include("common.jl")
include("unknowns_handler.jl")
include("output.jl")
include("domain_conditions.jl")
include("../mesh/mesh.jl")
include("assembler.jl")
include("solver.jl")
include("base_equation.jl")
include("validator.jl")
include("../models/register.jl")


"""Main function of the Wave simulator that runs the simulation"""
function run_simulation(parsed_args)
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
    
    main_loop(
        model, 
        simulation_data["simulation"]["steps_limit"], 
        parsed_args["show-progress"]
    )
end


"""The main loop"""
function main_loop(model, total_step_limits, show_progress)
    # TODO: write elapsed time and total steps elapsed (and log it)
    elapsed_time = 0.0
    running = true
    success = false
    timestep_counter = 0
    # TODO: wrap here the main loop with the progress
    # https://github.com/timholy/ProgressMeter.jl?tab=readme-ov-file#conditionally-disabling-a-progress-meter
    # progress = ProgressUnknown("running... ", spinner=true, color = :white)  

    # elapsed_time = @elapsed begin   
        # run main loop 
        while running 
            timestep_counter += 1
            # ProgressMeter.next!(progress)
            run_iteration(model)
            #println(timestep_counter)

            # stop simulation loop if converged
            success = all(values(model.unknowns_handler.converged))
            if success || timestep_counter == total_step_limits
                # force to write the result at last time step
                force_write_result = true
                running = false
            else
                force_write_result = false
                
            end

            # output the current time step result
            write_result_data(
                model.output_handler, 
                model.unknowns_handler, 
                timestep_counter,
                force_write_result
            )
        end
    # end # elapsed macro

    write_additional_data(model.output_handler, success, timestep_counter, elapsed_time)
    close_files(model.output_handler)
end

end # module