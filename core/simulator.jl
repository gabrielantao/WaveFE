module Wave

using TOML
using Statistics
using Dates
using SparseArrays
using LinearAlgebra
using ResumableFunctions
using ProgressMeter
using Preconditioners
using IterativeSolvers
using HDF5
using ArgParse

# TODO: include all the modules and files here
include("constants.jl")


include("./models/register.jl")


function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "folder"
            help = "path folder for simulation files"
            required = true
    end

    return parse_args(s)
end


function run_simulator()
    # parse args from comand line
    parsed_args = parse_commandline()
    folder = parsed_args["folder"]

    # setup simulation structures
    simulation_parameters = TOML.parsefile(joinpath(folder, "cache", "simulation.toml"))

    # file with input relevant data to build Simulator struct
    input_data = h5open(joinpath(folder, "cache", "input.hdf5"), "r")

    model = get_model(input_data, simulation_parameters)
    mesh = load_mesh(input_data, simulation_parameters)
    domain_conditions = load_domain_conditions(input_data, simulation_parameters)
    
    # TODO: load parameters to the right structs, e.g. tolerances to the checker and solver

    # TODO: create output manager here
    # create output handler
    output_manager = create_output_manager(
        folder,
        simulation_info["output"]["frequency"],
        simulation_info["output"]["save_result"],
        simulation_info["output"]["save_numeric"],
        simulation_info["output"]["save_debug"]
    )

    # run the main loop
    main_loop(
        model,
        mesh,
        domain_conditions,
        output_manager,
        simulation_parameters
    )
end


function main_loop(
    model,
    mesh,
    domain_conditions,
    output_manager,
    simulation_parameters,
    
)
    # TODO: fix this function ....

    total_step_limits = simulation_parameters["simulation"]["steps_limit"]
    # progress = ProgressUnknown("running... ", spinner=true, color = :white)
    # # values that come from cache info and simulation file
    # parameters = Dict{String, Float64}(simulation_info["parameter"])
    # safety_factor = simulation_info["simulation"]["safety_dt_factor"]
    # simulation_method = simulation_info["simulation"]["method"]
    # steps_limit = simulation_info["simulation"]["steps_limit"]
    # tolerance_absolute = Dict{String, Float64}(
    #     simulation_info["simulation"]["tolerance_absolute"]
    # )
    # tolerance_relative = Dict{String, Float64}(
    #     simulation_info["simulation"]["tolerance_relative"]
    # )

    # timestep_counter = 1
    # elapsed_time = @elapsed begin 
    #     # Run main loop 
    #     for timestep_counter in range(1, steps_limit) 
    #         ProgressMeter.next!(progress)

    #         # update all mesh properties
    #         update(mesh, parameters, safety_factor)
            
    #         # calculate one cbs step
    #         calculate_cbs_step(solver, mesh, simulation_method, parameters)

    #         # update convergence status
    #         convergence = check_variables_convergence(
    #             mesh.nodes, 
    #             tolerance_absolute,
    #             tolerance_relative
    #         )
            
    #         # write results to output file and convergence
    #         write_result_data(output, mesh.nodes, timestep_counter)
    #         write_convergence_data(output, convergence, timestep_counter)

    #         # stop simulation loop if converged
    #         if all([converge for converge in values(convergence)])  
    #             break
    #         end 

    #         # copy last result to a buffer in nodes (old_values)
    #         update_old_values(mesh.nodes)

    #         # reset simulation flags
    #         mesh.changed = false           
    #     end
    #     ProgressMeter.finish!(progress)
    # end # elapsed time macro
    # write_additional_result_data(
    #     output, 
    #     Dict{String, Any}("elapsed_time" => elapsed_time)
    # )
    # close_files(output)
end

##############################
### RUN THE WAVE SIMULATOR ###
##############################
run_simulator()

end # end module
