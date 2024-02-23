"""The first equation of the model semi-implicit"""
struct EquationStepTwo <: Equation
    # common data ("base class" data)
    base::BaseModelEquation
    # the safety_dt_factor used to calculate local Δt for the elements
    safety_dt_factor::Float64

    function EquationStepTwo(simulation_parameters)   
        solved_unknowns = ["p"]
        # TODO: this should be in a section model in the input file
        #use_lumped_mass = !simulation_parameters["simulation"]["transient"]
        safety_dt_factor = simulation_parameters["simulation"]["safety_dt_factor"]
        assembler = Assembler(SYMMETRIC)
        solver = load_solver(simulation_parameters)
        members = EquationMembers()

        base = BaseModelEquation(
            "Equation step 2 of semi-implicit CBS", 
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
function get_element_lhs(equation::EquationStepTwo, element::Segment)
end


function get_element_lhs(equation::EquationStepTwo, element::Triangle)
    # return the assembled element
    return []
end


# TODO: Implement this function
function get_element_lhs(equation::EquationStepTwo, element::Quadrilateral)
end


# TODO: Implement this function
function get_element_rhs(equation::EquationStepTwo, element::Segment)
end


function get_element_rhs(equation::EquationStepTwo, element::Triangle)
    # return the assembled element
    return []
end


# TODO: Implement this function
function get_element_rhs(equation::EquationStepTwo, element::Quadrilateral)
end