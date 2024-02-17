mutable struct ModelEquation
    # a label string for this equation
    label::String
    # the list of unknowns solved in this equation (e.g. velocity in x and y directions)
    solved_unknowns::Vector{String}
    # the assembler for this equation
    # TODO: the sparse LHS assembled matrix for this equation is preallocated when the equation is created
    assembler::Assembler
    # the solver  for this equation
    solver::Solver
    # LHS matrix with domain conditions applied, the key is the unknown label
    lhs::Dict{String, SparseMatrixCSC{Float64, Int32}}
    # RHS matrix to be solved for each unknown, the key is the unknown label
    rhs::Dict{String, Vector{Float64}}
end


"""
Compute a solution for the current asssembled equation.
And save it to the unkowns_handler

NOTE: The way domain conditions are applied the RHS conditions 
depends on LHS so if LHS need to be update so do RHS.
"""
function solve!(
    equation::ModelEquation,
    mesh::Mesh,
    unknowns_handler::UnkownsHandler,
    domain_conditions::DomainConditions,
    must_update_lhs::Bool=true,
    must_update_rhs::Bool=true,
)
    if must_update_lhs
        assemble_lhs(equation.assembler, mesh, parameters)
        assemble_rhs(equation.assembler, mesh, parameters)
    else
        if must_update_rhs
            assemble_rhs(equation.assembler, mesh, parameters)
        end    
    end
    
    #output_manager.write_debug(f"{self.label}/lhs_assembled", self.lhs_assembled)
    #output_manager.write_debug(f"{self.label}/rhs_assembled", self.rhs_assembled)
    
    # TODO: this could be done in parallel
    for unknown in equation.solved_unknowns
        if must_update_lhs
            # it uses assembled_lhs as template for all variables so it needs to copy here 
            # update the LHS matrix
            equation.lhs[unknown] = copy(equation.assembler.lhs)
            apply_domain_conditions_lhs!(
                domain_conditions, unknown, equation.lhs[unknown]
            )
            # update the RHS vector
            equation.rhs[unknown] = assembler.rhs[unknown]
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
