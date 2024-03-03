export Solver
export SolverType, SolverPreconditioners

@enum SolverType begin
    CONJUGATE_GRADIENT = 1
end

@enum SolverPreconditioners begin
    JACOBI = 1 # AKA DiagonalPreconditioner
end

"""Solver holds data for matrices that are used to solve boundary problem"""
mutable struct Solver
    type::SolverType
    preconditioner_type::SolverPreconditioners
    steps_limit::Int64
    relative_tolerance::Float64
    absolute_tolerance::Float64
    preconditioners::Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}
end


"""Load data for the solver"""
function load_solver(simulation_parameters)
    if simulation_parameters["solver"]["name"] == "Conjugate Gradient"
        solver_type = CONJUGATE_GRADIENT::SolverType
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for solvers
        throw("Not implemented yet other types of solvers")
    end
    if simulation_parameters["solver"]["preconditioner"] == "Jacobi"
        preconditioner_type = JACOBI::SolverPreconditioners
        preconditioners = Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}()
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for preconditioners
        throw("Not implemented yet other types of preconditioners")
    end
    
    return Solver(
        solver_type,
        preconditioner_type,
        simulation_parameters["solver"]["steps_limit"],
        simulation_parameters["solver"]["tolerance_relative"],
        simulation_parameters["solver"]["tolerance_absolute"],
        preconditioners
    )
end


"""Update the preconditioner used to solve the equation for this variable"""
function update_preconditioner!(
    solver::Solver, 
    lhs::SparseMatrixCSC{Float64, Int64},
    unknown::String
)
    if solver.preconditioner_type == JACOBI::SolverPreconditioners
        solver.preconditioners[unknown] = DiagonalPreconditioner(lhs)
    else
        # TODO [add solvers and preconditioner options]
        ## select the preconditioner to be used here
        throw("Not implemented yet other types of preconditioners")
    end
end


"""Solve a variable and save in result vector"""
function solve!(
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
    if solver.type == Wave.CONJUGATE_GRADIENT::SolverType
        unknowns_handler.values[unknown], info = cg(
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
end