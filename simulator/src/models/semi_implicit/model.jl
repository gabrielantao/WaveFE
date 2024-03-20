module ModuleSemiImplicit

using LinearAlgebra: dot
using Statistics: mean
using SparseArrays
using Preconditioners
using IterativeSolvers

# exported variables and methods
export ModelSemiImplicit, run_iteration, startup_model


###############################################
###############################################
# TODO [implement model with heat transfer]
## maybe this block of code include could be automatically generated via a macro
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
# TODO [add basic documentation]
"""
struct ModelSemiImplicit <: SimulationModel
    name::String
    unknonws::Vector{String}
    equations::Vector{Equation}
    unknowns_handler::UnknownsHandler
    additional_parameters::ModelSemiImplicitParameters

    function ModelSemiImplicit(case::SimulationCase)
        # configure the additional model parameters
        additional_parameters = ModelSemiImplicitParameters(
            case.simulation_data.simulation.transient,
            case.simulation_data.simulation.safety_Δt_factor,
            case.simulation_data.parameter.parameters
        )

        # define the unknowns for this model
        # velocities solved in the equation one and three depend on mesh dimension
        unknowns_velocities = ["u_$i" for i in range(1, Int64(case.mesh_data.dimension))]
        unknown_pressure = ["p"]
        all_solved_unknowns = [unknowns_velocities; unknown_pressure]

        # build the equations used for this model
        equations = [
            EquationStepOne(unknowns_velocities, case.simulation_data),
            EquationStepTwo(unknown_pressure, case.simulation_data),
            EquationStepThree(unknowns_velocities, case.simulation_data),
        ]
 
        # load the initial values for the unknowns
        unknowns_default_values = Dict{String, Float64}(
            unknown => 0.0 for unknown in unknowns_velocities
        )
        unknowns_default_values["p"] = 0.0001
        unkowns_handler = WaveCore.build_unknowns_handler(
            unknowns_default_values, 
            case.mesh_data,
            case.simulation_data,
            case.domain_conditions_data 
        )
        new(
            MODEL_NAME, 
            MODEL_UNKNOWNS,
            equations,
            unkowns_handler, 
            additional_parameters
        )
    end
end

"""Setup the model before to run the simulation"""
function startup_model(
    model::ModelSemiImplicit, 
    mesh::Mesh, 
    domain_conditions::DomainConditions
)
    WaveCore.setup_boundary_values!(
        domain_conditions, 
        model.unknowns_handler
    )
end


"""Run one iteration for this model"""
function run_iteration(
    model::ModelSemiImplicit, 
    mesh::Mesh, 
    domain_conditions::DomainConditions,
    output_handler::OutputHandler
) 
    # update elements internal data
    WaveCore.update_elements!(
        mesh, 
        model.unknowns_handler, 
        model.additional_parameters
    )
    
    # update the unknowns by coping current values to the old values
    WaveCore.update!(model.unknowns_handler)

    # solve the sequence of registered equations for each variable
    for equation in model.equations
        ### ASSEMBLE THE EQUATION ###
        if mesh.must_refresh
            # for the current equation preallocate the assembled LHS if
            # mesh is marked as "must refresh" status (e.g. if it was remeshed)
            WaveCore.update_assembler_indices!(
                equation.base.assembler, 
                mesh
            )
        end
        
        # TODO [general performance improvements]
        ## this call for LHS assembler could be done only if the mesh has updated
        ## the previous implementation used `if mesh.must_refresh || mesh.nodes.moved`
        ## but this breaks the simulation. Investigate if this is possible and if it can 
        ## improve the performance once it doens't need to redo this to obtain the same saved result
        ## One should try to move the dependency of Δt in the LHS to the RHS 
        ## then LHS will depend only on the geometrical data
        equation.base.assembler.assembled_lhs = assemble_global_lhs(
            equation, 
            mesh,
            model.unknowns_handler,
            model.additional_parameters
        )
        
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
            
            # TODO [general performance improvements]
            ## these calls for LHS and update preconditioner could be done only if the mesh has updated
            ## the previous implementation used `if mesh.must_refresh || mesh.nodes.moved`
            ## but this breaks the simulation. Investigate if this is possible and if it can 
            ## improve the performance once it doens't need to redo this to obtain the same saved result

            # it uses assembled_lhs as template for all variables so it needs to copy here 
            # update the LHS matrix
            equation.base.members.lhs[unknown] = copy(equation.base.assembler.assembled_lhs)
            WaveCore.apply_domain_conditions_lhs!(
                domain_conditions, 
                unknown, 
                equation.base.members.lhs[unknown]
            )
            # use the new built LHS to update the solver perconditioner
            WaveCore.update_preconditioner!(
                equation.base.solver, 
                equation.base.members.lhs[unknown], 
                unknown
            )
            # for this model always reapply the conditions for reassembled RHS
            equation.base.members.rhs[unknown] = WaveCore.apply_domain_conditions_rhs(
                domain_conditions, 
                unknown, 
                equation.base.assembler.assembled_lhs, 
                assembled_rhs[unknown]
            )

            ### SOLVE THE EQUATION ###
            solve!(equation, unknown, model.unknowns_handler)
            # force the boundary conditions 
            WaveCore.setup_boundary_values!(
                domain_conditions, model.unknowns_handler
            )
        end
    end

    # do the updates for the mesh (e.g. movement, remesh, etc.)
    WaveCore.update!(mesh)

    # TODO [general performance improvements]
    ## - it should check if it is diverging to abort simulation
    # TODO [add validation cases for the semi implicit]
    ## - review the metrics to calculate convergence
    WaveCore.check_unknowns_convergence!(model.unknowns_handler)
end


end # module