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
    steps_limit::Int32
    relative_tolerance::Float64
    absolute_tolerance::Float64
    preconditioner::Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}
end


"""Load data for the solver"""
function load_solver(simulation_parameters)
    if simulation_parameters["solver"]["name"] == "Conjugate Gradient"
        solver_type = CONJUGATE_GRADIENT::SolverType
    else
        throw("Not implemented yet other types of preconditioners")
        # TODO: add other options for preconditioners
    end
    if simulation_parameters["solver"]["preconditioner"] == "Jacobi"
        preconditioner_type = JACOBI::SolverPreconditioners
    else
        throw("Not implemented yet other types of preconditioners")
        # TODO: add other options for preconditioners
    end
    
    return Solver(
        solver_type,
        preconditioner_type,
        simulation_parameters["solver"]["steps_limit"],
        simulation_parameters["solver"]["tolerance_relative"],
        simulation_parameters["solver"]["tolerance_absolute"],
    )
end


"""Update the preconditioner used to solve the equation for this variable"""
function update_preconditioner(
    solver::Solver, 
    lhs::SparseMatrixCSC{Float64, Int32},
    unknown_label::String
)
    # TODO: select the preconditioner to be used here instead of this default here
    solver.preconditioner[unknown_label] = DiagonalPreconditioner(lhs)
end


"""Solve a variable and save in result vector"""
function calculate_solution!(
    solver::Solver,
    unknown::String,
    lhs::SparseMatrixCSC{Float64, Int32},
    rhs::Vector{Float64},
    unknowns_handler::UnknownsHandler
)
    # logger.info(
    #     f"solving variable {unknown_label}..."
    # )
    # TODO: implement other options of solvers here
    cg!(
        unknowns_handler.values[unknown],
        lhs,
        rhs,
        Pl=solver.preconditioners[unknown]       
    )
    # TODO: log the status of solver inside this function
    #       catch convergence log by doing log=true and save data (NUMERIC)
    # TODO: write numeric for each dimension here.  
end