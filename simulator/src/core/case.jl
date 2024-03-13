"""
The simulation case is responsable for:
- import all files needed to run a simulation case (e.g. mesh, parameters, conditions)
- validate the input files to ensure consistency and avoid invalid breaking the simulation
- manage the simulation and cached files for the simulation  
"""
struct SimulationCase
    folder::String
    # check if case changed compared to the cached inputs
    # case_changed::Bool 
    mesh_data::HDF5
    simulation_data::SimulationData
    domain_conditions_data::ConditionsData
end


function load_simulation_case(folder::String)
    # TODO: do the preprocessing here 
    # - create the cache (if needed) or overwrite (can be done after in other task)
    # - check if really need rerun the simulation (if something changed) use bson to save files
    #   must pass a flag (force-run) to run even if the input files did not changed
    # - run the mesh and create the input 
    mesh_data = h5open(joinpath(folder, SIMULATION_MESH_FILENAME), "r")
    simulation_data = SimulationData(
        TOML.parsefile(joinpath(folder, SIMULATION_INPUT_FILENAME))
    )
    domain_conditions_data = ConditionsData(
        TOML.parsefile(joinpath(folder, DOMAIN_CONDITIONS_FILENAME))
    )
    
    # do the logical validations for the inputs
    validate(simulation_data)
    validate(domain_conditions_data)

    # TODO create the cache hre with the case ....
    #cache_filepath = joinpath(folder, CACHE_PATH)
    
    return SimulationCase(
        folder,
        mesh_data,
        simulation_data,
        domain_conditions_data,
        logger
    )
end


"""Get the path for the cache folder for the current case"""
function get_cache_folder(case::SimulationCase) 
    return joinpath(case.folder, CACHE_PATH)
end