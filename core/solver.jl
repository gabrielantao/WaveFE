"""Solver holds data for matrices that are used to solve boundary problem"""
mutable struct Solver
    preconditioner::Dict{String, DiagonalPreconditioner{Float64, Vector{Float64}}}
    # TODO: check here the tolerances as parameters from simulation parameters
    #       and remember to load these values from configurations
    # relative_tolerance::Dict{String, Float64}
    # absolute_tolerance::Dict{String, Float64}
    # maximum_iterations::Dict{String, Int32}
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