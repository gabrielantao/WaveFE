struct OutputHandler
    save_frequency::Int64
    save_result::Bool
    save_numeric::Bool
    save_debug::Bool
    result_file::HDF5.File
    numeric_file::HDF5.File
    debug_file::HDF5.File
end

"""Create all output files"""
function create_output(
    folder::String, 
    frequency::Int64,
    save_result::Bool, 
    save_numeric::Bool, 
    save_debug::Bool
)
    return OutputHandler(
        frequency,
        save_result,
        save_numeric,
        save_debug,
        h5open(joinpath(folder, "result", "result.hdf5"), "w"),
        h5open(joinpath(folder, "result", "numeric.hdf5"), "w"),
        h5open(joinpath(folder, "result", "debug.hdf5"), "w")
    )
end


"""Close all output files"""
function close_files(output::OutputHandler)
    close(output.result_file)
    close(output.numeric_file)
    close(output.debug_file)
end


"""Write results for each variable and each node"""
function write_result_data(
    output::OutputHandler, 
    nodes::Nodes, 
    current_step::Int64
)
    if output.save_result
        # TODO: it should save Δt as well
        if current_step % output.save_frequency == 0
            for (variable, values) in nodes.values
                output.result_file["result/$current_step/$variable"] = values
            end                
        end
    end
end


"""Write convergence data for each variable and each node"""
function write_convergence_data(
    output::OutputHandler, 
    convergence::Dict{String, Bool}, 
    current_step::Int64,
)
    if output.save_result
        for (variable, converge) in convergence
            output.result_file["convergence/$current_step/$variable"] = converge
        end
    end
end


"""Write additional data to the result file"""
function write_additional_result_data(
    output::OutputHandler, 
    additional_data::Dict{String, Any}
)
    for (key, data) in additional_data
        output.result_file[key] = data
    end
end


