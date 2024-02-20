"""The first equation of the model semi-implicit"""
struct EquationStepOne <: Equation
    # common data ("base class" data)
    base::BaseModelEquation
    # if the assembler should use the diagonal matrix for the elements
    use_lumped_mass::Bool
    # the safety_dt_factor used to calculate local Δt for the elements
    safety_dt_factor::Float64

    function EquationStepOne(simulation_parameters)   
        solved_unknowns = ["u_1", "u_2", "u_3"]
        # TODO: this should be in a section model in the input file
        use_lumped_mass = !simulation_parameters["simulation"]["transient"]
        safety_dt_factor = simulation_parameters["simulation"]["safety_dt_factor"]
        lhs_diagonal = use_lumped_mass
        lhs_symetric = true
        assembler = Assembler(lhs_diagonal, lhs_symetric)
        solver = load_solver(simulation_parameters)
        members = EquationMembers()

        base = BaseModelEquation(
            "Equation step 1 of semi-implicit CBS", 
            solved_unknowns, 
            assembler, 
            solver, 
            members,
        )
        new(
            base,
            use_lumped_mass,
            safety_dt_factor
        )
    end
end


# TODO: Implement this function
function assemble(equation::EquationStepOne, element::Segment)
end


function assemble(equation::EquationStepOne, element::Triangle)
    # return the assembled element
    return []
end


# TODO: Implement this function
function assemble(equation::EquationStepOne, element::Quadrilateral)
end




###########################################
# metodo da classe element container 
# o Assembler eh o visitor
function assemble(triangle_container, assembler)
    for triangle in triangle_container
        # chama o metodo da classe assembler que faz montagem de um elemento
        # do tipo triangulo
        assemble_triangle(assembler, triangle)

    end
end


# aqui eh da classe assembler
function assemble_triangle(assembler, triangle)

end
