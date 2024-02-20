"""The first equation of the model semi-implicit"""
struct EquationStepThree <: Equation
    # common data ("base class" data)
    base::BaseModelEquation
    # if the assembler should use the diagonal matrix for the elements
    use_lumped_mass::Bool
    # the safety_dt_factor used to calculate local Δt for the elements
    safety_dt_factor::Float64

    function EquationStepThree(simulation_parameters)   
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
            "Equation step 3 of semi-implicit CBS", 
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
function assemble(equation::EquationStepThree, element::Segment)
end


function assemble(equation::EquationStepThree, element::Triangle)
    # return the assembled element
    return []
end


# TODO: Implement this function
function assemble(equation::EquationStepThree, element::Quadrilateral)
end