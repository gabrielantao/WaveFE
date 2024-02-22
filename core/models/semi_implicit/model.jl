module ModuleSemiImplicit

using LinearAlgebra
using SparseArrays
using Preconditioners
using IterativeSolvers

# implementation for the mesh and domain conditions
# to be used by this model
include("../../common.jl")
include("../../mesh/mesh.jl")
include("../../domain_conditions.jl")
include("../../base_equation.jl")
include("../../unknowns_handler.jl")

# get the assembled equations
include("./equations/equation_one.jl")
include("./equations/equation_two.jl")
include("./equations/equation_three.jl")


"""Additional parameters from the input file"""
struct ModelSemiImplicitParameters <: ModelParameters
    transient::Bool
    adimensionals::Dict{String, Float64}
end


"""
Semi-implicit model
TODO: include description here ....
"""
struct ModelSemiImplicit
    name::String
    mesh::Mesh
    domain_conditions::DomainConditions
    unknowns_handler::Vector{String}
    equations::Vector{ModelEquation}
    additional_parameters::ModelSemiImplicitParameters

    function ModelSemiImplicit(input_data, simulation_parameters)
        unkowns_handler = load_unkowns_handler(input_data, simulation_parameters)
        mesh = load_mesh(input_data, simulation_parameters)
        domain_conditions = load_domain_conditions(input_data)

        # configure the additional model parameters
        transient = simulation_parameters["simulation"]["transient"]
        adimensionals = simulation_parameters["parameter"]
        additional_parameters = ModelSemiImplicitParameters(
            transient,
            adimensionals
        )

        # build the equations used for this model
        equations = [
            EquationStepOne(simulation_parameters),
            EquationStepTwo(simulation_parameters),
            EquationStepThree(simulation_parameters),
        ]

        new(
            "CBS Semi-implicit", 
            mesh,
            domain_conditions,
            unkowns_handler, 
            equations,
            additional_parameters
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
        # for the current equation preallocate the assembled LHS
        # if mesh is marked as "must refresh" status (e.g. if it was remeshed)
        if mesh.must_refresh
            reassign_lhs_indices!(equation.assembler)
        end
        if mesh.must_refresh || mesh.nodes.moved
            assembled_lhs = assemble_global_lhs(equation, mesh)
        end
        # for this model always reassemble RHS
        assembled_rhs = assemble_global_rhs!(equation, mesh)

        # TODO: the domain conditions and solve could be done in parallel for each unknown
        for unknown in equation.solved_unknowns
            ### APPLY DOMAIN CONDITIONS ###
            if mesh.must_refresh || mesh.nodes.moved
                # it uses assembled_lhs as template for all variables so it needs to copy here 
                # update the LHS matrix
                equation.members.lhs[unknown] = copy(assembled_lhs)
                apply_domain_conditions_lhs!(
                    model.domain_conditions, unknown, equation.members.lhs[unknown]
                )
                # use the new built LHS to update the solver perconditioner
                update_preconditioner(equation.solver, equation.members.lhs[unknown], unknown)
            end
            # for this model always reapply the conditions for reassembled RHS
            equation.rhs[unknown] = assembled_rhs[unknown]
            apply_domain_conditions_rhs!(
                domain_conditions, 
                unknown, 
                equation.assembler.lhs, 
                equation.members.rhs[unknown]
            )

            ### SOLVE THE EQUATION ###
            solve!(
                equation.solver,
                unknown,
                equation.members.lhs[unknown],
                equation.members.rhs[unknown],
                model.unknowns_handler
            )
        end
    end

    # do the updates for the mesh (e.g. movement, remesh, etc.)
    update!(mesh)
    
    # TODO: it should check if it is diverging to abort simulation
    check_unknowns_convergence!(model.unknowns_handler)
end


end # module