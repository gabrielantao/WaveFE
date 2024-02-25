"""This struct holds the sizes of the equation"""
mutable struct EquationMembers
    # LHS matrix with domain conditions applied, the key is the unknown label
    lhs::Dict{String, SparseMatrixCSC{Float64, Int64}}
    # RHS matrix to be solved for each unknown, the key is the unknown label
    rhs::Dict{String, Vector{Float64}}

    function EquationMembers()
        new(
            Dict{String, sparse([], [], Float64[])}(),
            Dict{String, Vector{Float64}}()
        )
    end
end


"""This struct keeps all common data for an equation struct"""
mutable struct BaseModelEquation
    # a short description of this equation
    description::String
    # the list of unknowns solved in this equation (e.g. velocity in x and y directions)
    solved_unknowns::Vector{String}
    # the assembler for this equation
    assembler::Assembler
    # the solver  for this equation
    solver::Solver
    # right-hand and left-hand side of the equation
    members::EquationMembers
end
