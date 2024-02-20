"""A generic equation"""
abstract type Equation end


"""This struct holds the sizes of the equation"""
mutable struct EquationMembers
    # LHS matrix with domain conditions applied, the key is the unknown label
    lhs::Dict{String, SparseMatrixCSC{Float64, Int32}}
    # RHS matrix to be solved for each unknown, the key is the unknown label
    rhs::Dict{String, Vector{Float64}}

    function EquationMembers()
        new(
            Dict{String, SparseMatrixCSC{Float64, Int32}}(),
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


# TODO: review this function for the new struct of the equations!!!

"""
Compute a solution for the current asssembled equation.
And save it to the unkowns_handler

NOTE: The way domain conditions are applied the RHS conditions 
depends on LHS so if LHS need to be update so do RHS.
"""
function solve!(
    equation::Equation,
    mesh::Mesh,
    unknowns_handler::UnkownsHandler,
    domain_conditions::DomainConditions,
    must_update_lhs::Bool=true,
    must_update_rhs::Bool=true,
)
    if must_update_lhs
        assembled_lhs = assemble_lhs(equation.assembler, mesh, parameters)
        assembled_rhs =  assemble_rhs(equation.assembler, mesh, parameters)
    else
        if must_update_rhs
            assembled_rhs = assemble_rhs(equation.assembler, mesh, parameters)
        end    
    end
    
    #output_manager.write_debug(f"{self.label}/lhs_assembled", self.lhs_assembled)
    #output_manager.write_debug(f"{self.label}/rhs_assembled", self.rhs_assembled)
    
    # TODO: this could be done in parallel
    for unknown in equation.solved_unknowns
        if must_update_lhs
            # it uses assembled_lhs as template for all variables so it needs to copy here 
            # update the LHS matrix
            equation.lhs[unknown] = copy(assembled_lhs)
            apply_domain_conditions_lhs!(
                domain_conditions, unknown, equation.lhs[unknown]
            )
            # update the RHS vector
            equation.rhs[unknown] = equation.assembler.rhs[unknown]
            apply_domain_conditions_rhs!(
                domain_conditions, 
                unknown, 
                equation.assembler.lhs, 
                equation.rhs[unknown]
            )
            # use the new built LHS to update the solver perconditioner
            update_preconditioner(equation.solver, equation.lhs[unknown], unknown)
        else
            if must_update_rhs
                equation.rhs[unknown] = assembled_rhs[unknown]
                apply_domain_conditions_rhs!(
                    domain_conditions, 
                    unknown, 
                    equation.assembler.lhs, 
                    equation.rhs[unknown]    
                )    
            end
        end
        #logger.info(f"solving equation {equation.label}...")
        calculate_solution!(
            equation.solver,
            unknown,
            equation.lhs,
            equation.rhs,
            unknowns_handler
        )
    end
end
