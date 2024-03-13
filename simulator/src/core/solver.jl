export Solver
export SolverType, PreconditionerType
export load_solver

@enum SolverType begin
    CONJUGATE_GRADIENT = 1
end

@enum PreconditionerType begin
    JACOBI = 1 # AKA DiagonalPreconditioner
end

"""Solver holds data for matrices that are used to solve boundary problem"""
mutable struct Solver
    type::SolverType
    preconditioner_type::PreconditionerType
    steps_limit::Int64
    relative_tolerance::Float64
    absolute_tolerance::Float64
    preconditioners::Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}
end


"""Load data for the solver"""
function load_solver(simulation_data)
    preconditioner = get_preconditioner(simulation_data.solver.preconditioner_type)
    return Solver(
        simulation_data.solver.type,
        simulation_data.solver.preconditioner_type,
        simulation_data.solver.steps_limit,
        simulation_data.solver.tolerance_relative,
        simulation_data.solver.tolerance_absolute,
        preconditioner
    )
end


"""Get the type of solver selected in the simulation input options"""
function get_solver_type(type)
    if type == "Conjugate Gradient"
        solver_type = CONJUGATE_GRADIENT::SolverType
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for solvers
        throw("Not implemented yet other types of solvers")
    end
    return solver_type
end


"""Get the type of preconditioner selected in the simulation input options"""
function get_solver_preconditioner_type(preconditioner)
    if preconditioner == "Jacobi"
        preconditioner_type = JACOBI::PreconditionerType
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for preconditioners
        throw("Not implemented yet other types of preconditioners")
    end
    return preconditioner_type
end


"""Get an empty preconditioner"""
function get_preconditioner(preconditioner_type::PreconditionerType)
    if preconditioner_type == JACOBI::PreconditionerType
        preconditioners = Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}()
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for preconditioners
        throw("Not implemented yet other types of preconditioners")
    end
    return preconditioners
end


"""Update the preconditioner used to solve the equation for this variable"""
function update_preconditioner!(
    solver::Solver, 
    lhs::SparseMatrixCSC{Float64, Int64},
    unknown::String
)
    if solver.preconditioner_type == JACOBI::PreconditionerType
        solver.preconditioners[unknown] = DiagonalPreconditioner(lhs)
    else
        # TODO [add solvers and preconditioner options]
        ## select the preconditioner to be used here
        throw("Not implemented yet other types of preconditioners")
    end
end


"""Solve a variable and save in result vector"""
function calculate_solution(
    solver::Solver,
    unknown::String,
    lhs::SparseMatrixCSC{Float64, Int64},
    rhs::Vector{Float64},
    unknowns_handler::UnknownsHandler
)
    # logger.info(
    #     f"solving variable {unknown_label}..."
    # )
    # TODO [add solvers and preconditioner options]
    ## use the tolerance values in the solver
    if solver.type == WaveCore.CONJUGATE_GRADIENT::SolverType
        solution, info = cg(
            lhs,
            rhs,
            Pl=solver.preconditioners[unknown],
            log=true
        )
    else
        # TODO [add solvers and preconditioner options]
        ## add more options of solvers options 
        throw("Not implemented yet other types of solvers")
    end
    
    # TODO: log the status of solver inside this function
    #       catch convergence log by doing log=true and save data (NUMERIC)
    # TODO [implement better debugging tools]
    ## write numeric for each dimension here.  
    return solution
end