export Simulation

"""
Simulation => Case + Method + Model + control data
"""
struct Simulation
    case::SimulationCase
    method::SimulationMethod
    model::SimulationModel
    # TODO [implement explicit method]
    ## maybe the mesh and domain conditions should reside in the method struct
    mesh::Mesh
    domain_conditions::DomainConditions
    output_handler::OutputHandler
    logger::FileLogger
end


"""Build all components of the current simulation"""
function build_simulation(folder::String)
    # create the logger (to a log file)
    logger = FileLogger(joinpath(cache_folder, SIMULATOR_LOG_FILENAME))
    
    # TODO: log the case name and general data and folder before start
    # TODO: log the reading the input files and write message if break during validations

    # import the case files
    case = load_simulation_case(folder)

    # TODO [implement explicit method]
    ## implement data and functions for the explicit method and select the case here
    method = SemiImplicitMethod()

    # load the mesh and domain conditions (AKA boundary conditions)
    mesh = load_mesh(case.mesh_data, case.simulation_data)
    domain_conditions = load_domain_conditions(
        case.mesh_data, case.domain_conditions_data
    )

    # load and create the output handler and 
    output_handler = load_output_handler(get_cache_folder(case), case.simulation_data)
    
    # get the model based in the simulation model defined in input file
    model = build_model(case.simulation_data)

    return Simulation(
        case, method, model, mesh, domain_conditions, output_handler, logger
    )
end



"""Start the main loop"""
function start(simulation::Simulation, show_progress::Bool)
    running = true
    success = false
    timestep_counter = 0
    simulation_data = simulation.case.simulation_data
    progress_bar = Progress(
        simulation_data.simulation.steps_limit, 
        desc=simulation_data.general.alias, 
        enabled=show_progress,
        barglyphs=BarGlyphs('|','█', ['▁' ,'▂' ,'▃' ,'▄' ,'▅' ,'▆', '▇'],' ','|',),
        color=:white
    )  

    elapsed_time = @elapsed begin   
        # setup additional stuff before start the simulation
        startup_model(simulation.model, simulation.mesh, simulation.domain_conditions)
        
        # write the output values for the initial time step
        write_result_data(
            simulation.output_handler, 
            simulation.model.unknowns_handler, 
            timestep_counter
        )

        # run main loop 
        while running 
            timestep_counter += 1
            next!(progress_bar)

            # run the function that make one iteration for the model
            # and check if the simulation has converged
            run_iteration(
                simulation.model, simulation.mesh, simulation.domain_conditions
            )
            success = all(values(simulation.model.unknowns_handler.converged))
            if success || timestep_counter == total_step_limits
                # force to write the result at last time step
                force_write_result = true
                running = false
            else
                force_write_result = false  
            end

            # output the current time step result
            write_result_data(
                simulation.output_handler, 
                simulation.model.unknowns_handler, 
                timestep_counter,
                force_write_result
            )
        end
    end # elapsed macro

    # TODO should log  finhish and closing output files
    finish!(progress_bar)
    write_additional_data(simulation.output_handler, success, timestep_counter, elapsed_time)
    close_files(simulation.output_handler)
    # TODO: close the file logger file
end
