export OutputHandler

struct OutputHandler
    save_frequency::Int64
    saved_unknowns::Vector{String}
    save_intermediate_result::Bool
    save_intermediate_numeric::Bool
    save_debug::Bool
    result_file::HDF5.File
    debug_file::HDF5.File
    
end


"""Load data to create the output files handler for the simulation"""
function load_output_handler(simulation_folder, simulation_data)
    # create the path for the results here if it do not exist
    result_path = joinpath(simulation_folder, CACHE_PATH, RESULT_PATH)
    if !isfile(result_path)
        mkpath(result_path)
    end
    result_file = h5open(joinpath(result_path, RESULT_FILENAME), "w")
    debug_file = h5open(joinpath(result_path, DEBUG_FILENAME), "w")
    result_file["version"] = RESULT_FILE_CURRENT_VERSION
    result_file["description"] = simulation_data["general"]["description"]
    debug_file["version"] = DEBUG_FILE_CURRENT_VERSION
    debug_file["description"] = simulation_data["general"]["description"]

    return OutputHandler(
        simulation_data["output"]["frequency"],
        simulation_data["output"]["unknowns"],
        simulation_data["output"]["save_result"],
        simulation_data["output"]["save_numeric"],
        simulation_data["output"]["save_debug"],
        result_file,
        debug_file
    )
end


"""Write results for each variable and each node"""
function write_result_data(
    output_handler::OutputHandler, 
    unknowns_handler::UnknownsHandler, 
    current_step::Int64,
    force_write::Bool=false
)
    save_current_timestep = current_step % output_handler.save_frequency == 0
    # write the results of current iteraction for the selected variables
    if force_write || (output_handler.save_intermediate_result && save_current_timestep)
        # println("DENTRO $current_step")
        # TODO: it should save Δt as well
        for (unknown, values) in unknowns_handler.values
            if unknown in output_handler.saved_unknowns
                output_handler.result_file["result/$unknown/t_$current_step"] = values
            end
        end                
    end

    # write convergence data
    if force_write || (output_handler.save_intermediate_numeric && save_current_timestep)
        for (unknown, converged) in unknowns_handler.converged
            if unknown in output_handler.saved_unknowns
                output_handler.result_file["convergence/$unknown/t_$current_step"] = converged
            end
        end
    end
end


# TODO [implement mesh movement]
## write in the file the movement of mesh in each step
function write_mesh_data()
end


"""Write additional data to the numeric file"""
function write_additional_data(
    output_handler::OutputHandler,
    simulation_success::Bool,
    total_steps::Int64,
    elapsed_time::Float64
)
    output_handler.result_file["success"] = simulation_success
    output_handler.result_file["total_steps"] = total_steps
    output_handler.result_file["total_elapsed_time"] = elapsed_time
    
end


"""Close all output files"""
function close_files(output_handler::OutputHandler)
    # println("CLOSING")
    close(output_handler.result_file)
    close(output_handler.debug_file)
end