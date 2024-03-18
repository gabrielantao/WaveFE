export Solver
export load_solver


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
        ## - select the preconditioner to be used here
        ## - add message for list of available options
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
        ## - add more options of solvers options 
        ## - add message for list of available options
        throw("Not implemented yet other types of solvers")
    end
    
    # TODO: log the status of solver inside this function
    #       catch convergence log by doing log=true and save data (NUMERIC)
    # TODO [implement better debugging tools]
    ## write numeric for each dimension here.  
    return solution
end