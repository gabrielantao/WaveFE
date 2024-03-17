export SimulationCase

"""
The simulation case is responsable for:
- import all files needed to run a simulation case (e.g. mesh, parameters, conditions)
- manage the simulation and cached files for the simulation  
"""
struct SimulationCase
    folder::String
    has_changed::Bool 
    simulation_data::SimulationData
    domain_conditions_data::DomainConditionsData
    mesh_data::MeshData
end


"""Create the simulation case based on data from input files"""
function build_simulation_case(folder::String)
    # define the input file paths
    simulation_filepath = joinpath(abspath(folder), SIMULATION_FILENAME)
    domain_conditions_filepath = joinpath(abspath(folder), DOMAIN_CONDITIONS_FILENAME)
    mesh_filepath = joinpath(abspath(folder), MESH_FILENAME)
    
    # load the data from input files
    simulation_data = SimulationData(simulation_filepath)
    domain_conditions_data = load_domain_conditions_data(domain_conditions_filepath)
    mesh_data = load_mesh_data(mesh_filepath)
    
    # calculate the input data hashs
    current_simulation_data_hash = hash(simulation_data)
    current_domain_conditions_data = hash(domain_conditions_data)
    current_mesh_data_hash = hash(mesh_data)

    # create the cache if this don't exist and set default value for input_modified
    # then check using the hashs if something changed since last run
    cache_folder = joinpath(abspath(folder), CACHE_PATH)
    cached_data_filepath = joinpath(cache_folder, CACHED_DATA_FILENAME)
    mkpath(cache_folder)
    input_modified = true
    if isfile(cached_data_filepath)
        cached_data = TOML.parsefile(cached_data_filepath)
        # TODO [general performance improvements] 
        ## just regenerate data if needed, review this is really needed
        ## think about it, maybe the improvements may be negligible         
        input_modified = !all(
            [
                current_simulation_data_hash == cached_data["simulation"],
                current_domain_conditions_data == cached_data["domain_conditions"],
                current_mesh_data_hash == cached_data["mesh"] 
            ]
        )
    end

    # update cached data hash
    if input_modified
        # TODO [general performance improvements] 
        ## maybe it could use BSON to serialize data to make fast rerun
        ## then take advantage of previouslly preprocessed input in the cache
        ## think about it, maybe the improvements may be negligible  
        cached_data = Dict{String, UInt64}(
            "simulation" => current_simulation_data_hash,
            "domain_conditions" => current_domain_conditions_data,
            "mesh" => current_mesh_data_hash
        )
        open(cached_data_filepath, "w") do io
            mv(simulation_filepath, cache_folder, force=true)
            mv(domain_conditions_filepath, cache_folder, force=true)
            mv(mesh_filepath, cache_folder, force=true)
            TOML.print(io, cached_data)
        end
    end
    return SimulationCase(
        folder, 
        input_modified,
        simulation_data, 
        domain_conditions_data,
        mesh_data
    )
end


"""Get the path for the cache folder for the current case"""
get_cache_folder(case::SimulationCase) = abspath(joinpath(case.folder, CACHE_PATH))


"""Get the path for the reference results for the current case"""
get_reference_folder(case::SimulationCase) = abspath(joinpath(case.folder, REFERENCE_PATH))


"""Get the path for the cached results for the current case"""
get_result_folder(case::SimulationCase) = joinpath(get_cache_folder(case), RESULT_PATH)


"""Get the path for the log file for the current case"""
get_log_filepath(case::SimulationCase) = joinpath(get_result_folder(case), LOG_FILENAME)


"""Get the path for the mesh file results for the current case"""
get_result_filepath(case::SimulationCase) = joinpath(get_result_folder(case), RESULT_FILENAME)


"""Get the path for the mesh file results for the current case"""
get_debug_filepath(case::SimulationCase) = joinpath(get_result_folder(case), DEBUG_FILENAME)


## TODO [implement better debugging tools]
## One could create a tarball with the case folder. 
## This feature could be useful to "download" the case and it could be done like this:
## - rename the cache folder to something like "result_$datetime" 
## - create a tarball for the case path on the passed destiny
# function create_result_tarball()
# end