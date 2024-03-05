module ModuleSemiImplicit

using LinearAlgebra: dot
using Statistics: mean
using SparseArrays
using Preconditioners
using IterativeSolvers
using Logging, LoggingExtras

# exported variables and methods
export ModelSemiImplicit, run_iteration


###############################################
###############################################
# TODO: maybe this block of code include could be automatically generated via a macro
###############################################
############################################### START OF BLOCK

# TODO [general performance improvements]
## investigate if this is the proper way to include code in this module
## in order to take advantage of Julia precompilation
using ..WaveCore

# basic data for the model
include("header.jl")

# get the assembled equations
include("./equations/equation_one.jl")
include("./equations/equation_two.jl")
include("./equations/equation_three.jl")
include("../../core/global_assembling.jl")

###############################################
############################################### END OF BLOCK

"""
Semi-implicit model
TODO: include description here ....
"""
struct ModelSemiImplicit <: WaveModel
    name::String
    unknonws::Vector{String}
    equations::Vector{Equation}
    unknowns_handler::UnknownsHandler
    additional_parameters::ModelSemiImplicitParameters
    # TODO: review if these parameters should be here or somewhere else
    mesh::Mesh
    domain_conditions::DomainConditions
    output_handler::OutputHandler
    logger::FileLogger

    function ModelSemiImplicit(simulation_folder, input_data, simulation_data, domain_conditions_data)
        # load the mesh and domain conditions (AKA boundary conditions)
        mesh = WaveCore.load_mesh(input_data, simulation_data)
        domain_conditions = WaveCore.load_domain_conditions(input_data, domain_conditions_data)
        output_handler = WaveCore.load_output_handler(simulation_folder, simulation_data)
        logger = FileLogger(joinpath(simulation_folder, CACHE_PATH, SIMULATOR_LOG_FILENAME))

        # configure the additional model parameters
        transient = simulation_data["simulation"]["transient"]
        adimensionals = simulation_data["parameter"]
        safety_Δt_factor = simulation_data["simulation"]["safety_dt_factor"]
        additional_parameters = ModelSemiImplicitParameters(
            transient,
            safety_Δt_factor,
            adimensionals
        )

        # define the unknowns for this model
        # velocities solved in the equation one and three depend on mesh dimension
        unknowns_velocities = ["u_$i" for i in range(1, Int(mesh.dimension))]
        unknown_pressure = ["p"]
        all_solved_unknowns = [unknowns_velocities; unknown_pressure]

        # build the equations used for this model
        equations = [
            EquationStepOne(unknowns_velocities, simulation_data),
            EquationStepTwo(unknown_pressure, simulation_data),
            EquationStepThree(unknowns_velocities, simulation_data),
        ]

        # load the initial values for the unknowns
        unknowns_default_values = Dict(unknown => 0.0 for unknown in all_solved_unknowns)
        unkowns_handler = WaveCore.load_unknowns_handler(
            unknowns_default_values, 
            input_data,
            simulation_data,
            domain_conditions_data,
        )
        # setup the boundary values for the unknowns
        WaveCore.setup_boundary_values!(
            domain_conditions, unkowns_handler
        )

        new(
            MODEL_NAME, 
            MODEL_UNKNOWNS,
            equations,
            unkowns_handler, 
            additional_parameters,
            mesh,
            domain_conditions,
            output_handler,
            logger
        )
    end
end


"""Run one iteration for this model"""
function run_iteration(model::ModelSemiImplicit) 
    # update elements internal data
    update_elements!(mesh, unknowns_handler, model_parameters)
    
    # update the unknowns by coping current values to the old values
    update!(model.unknowns_handler)

    # solve the sequence of registered equations for each variable
    for equation in model.equations
        ### ASSEMBLE THE EQUATION ###
        if mesh.must_refresh
            # for the current equation preallocate the assembled LHS if
            # mesh is marked as "must refresh" status (e.g. if it was remeshed)
            update_assembler_indices!(equation.base.assembler, mesh)
        end
        if mesh.must_refresh || mesh.nodes.moved
            assembled_lhs = assemble_global_lhs(
                equation, 
                mesh,
                model.unknowns_handler,
                model.additional_parameters
            )
        end
        # for this model always reassemble RHS
        assembled_rhs = assemble_global_rhs(
            equation, 
            mesh,
            model.unknowns_handler,
            model.additional_parameters
        )

        # TODO [make the solver paralallel] 
        # the domain conditions and solve could be done in parallel for each unknown
        for unknown in equation.base.solved_unknowns
            ### APPLY DOMAIN CONDITIONS ###
            if mesh.must_refresh || mesh.nodes.moved
                # it uses assembled_lhs as template for all variables so it needs to copy here 
                # update the LHS matrix
                equation.base.members.lhs[unknown] = copy(assembled_lhs)
                apply_domain_conditions_lhs!(
                    model.domain_conditions, 
                    unknown, 
                    equation.base.members.lhs[unknown]
                )
                # use the new built LHS to update the solver perconditioner
                update_preconditioner!(
                    equation.base.solver, 
                    equation.base.members.lhs[unknown], 
                    unknown
                )
            end
            # for this model always reapply the conditions for reassembled RHS
            equation.base.members.rhs[unknown] = apply_domain_conditions_rhs(
                domain_conditions, 
                unknown, 
                equation.base.assembler.lhs, 
                assembled_rhs[unknown]
            )

            ### SOLVE THE EQUATION ###
            solve!(equation, unknown, model.unknowns_handler)
        end
    end

    # do the updates for the mesh (e.g. movement, remesh, etc.)
    update!(mesh)
    
    # TODO [general performance improvements]
    ## it should check if it is diverging to abort simulation
    check_unknowns_convergence!(model.unknowns_handler)
end


end # module