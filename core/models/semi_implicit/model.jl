module ModuleSemiImplicit

using LinearAlgebra
using SparseArrays
using Preconditioners
using IterativeSolvers

# TODO [general performance improvements]
## investigate if this is the proper way to include code in this module
## in order to take advantage of Julia precompilation

# import all used common code to all models
include("../../common.jl")
include("../../unknowns_handler.jl")
include("../../domain_conditions.jl")
include("../../mesh/mesh.jl")
include("../../assembler.jl")
include("../../solver.jl")
include("../../base_equation.jl")


# exported variables and methods
export run_iteration


"""Additional parameters from the input file"""
struct ModelSemiImplicitParameters <: ModelParameters
    transient::Bool
    adimensionals::Dict{String, Float64}
end


const MODEL_NAME = "CBS Semi-Implicit"
const MODEL_UNKNOWNS = ["u_1", "u_2", "u_3", "p"]


# get the assembled equations
include("./equations/equation_one.jl")
include("./equations/equation_two.jl")
include("./equations/equation_three.jl")


"""
Semi-implicit model
TODO: include description here ....
"""
struct ModelSemiImplicit
    name::String
    unknonws::Vector{String}
    mesh::Mesh
    domain_conditions::DomainConditions
    equations::Vector{Equation}
    unknowns_handler::UnknownsHandler
    additional_parameters::ModelSemiImplicitParameters

    function ModelSemiImplicit(input_data, simulation_data, domain_conditions_data)
        mesh = load_mesh(input_data, simulation_data)
        domain_conditions = load_domain_conditions(
            get_domain_condition_groups(mesh.nodes),
            domain_conditions_data
        )

        # configure the additional model parameters
        transient = simulation_data["simulation"]["transient"]
        adimensionals = simulation_data["parameter"]
        additional_parameters = ModelSemiImplicitParameters(
            transient,
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
            EquationStepThree(unknonws_velocities, simulation_data),
        ]

        # setup initial values for the unknowns
        unkowns_handler = load_unknowns_handler(
            all_solved_unknowns, 
            get_domain_condition_groups(mesh.nodes),
            domain_conditions_data
        )
        setup_boundary_values(
            domain_conditions, unkowns_handler
        )

        new(
            MODEL_NAME, 
            MODEL_UNKNOWNS,
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
        if mesh.must_refresh
            # for the current equation preallocate the assembled LHS if
            # mesh is marked as "must refresh" status (e.g. if it was remeshed)
            update_assembler_indices!(equation.assembler, mesh)
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
    
    # TODO [general performance improvements]
    ## it should check if it is diverging to abort simulation
    check_unknowns_convergence!(model.unknowns_handler)
end


end # module