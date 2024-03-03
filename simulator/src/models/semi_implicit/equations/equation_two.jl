"""The first equation of the model semi-implicit"""
struct EquationStepTwo <: Equation
    # common data ("base class" data)
    base::BaseModelEquation

    function EquationStepTwo(solved_unknowns, simulation_parameters)   
        # TODO: this should be in a section model in the input file
        assembler = Assembler(WaveCore.SYMMETRIC::MatrixType)
        solver = load_solver(simulation_parameters)
        members = EquationMembers()

        base = BaseModelEquation(
            "Equation step 2 of semi-implicit CBS", 
            solved_unknowns, 
            assembler, 
            solver, 
            members,
        )
        new(base)
    end
end


# TODO [implement one dimensional elements]
# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepTwo, 
    element::Segment,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented unidimensional elements assembling")
end


# TODO [implement one dimensional elements]
# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepTwo, 
    element::Segment, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented unidimensional elements assembling")
end


# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepTwo, 
    element::Triangle, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    # TODO [general performance improvements]
    ## check if is possible to use this Δt divided in RHS instead of here
    ## this avoids the LHS be recalculated every time step for this equation
    return element.Δt * element.area * (element.b * element.b' + element.c * element.c') 
end


# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepTwo, 
    element::Triangle, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    # TODO [review the equation formulations] 
    ## check forcing vectors in this assembling process
    ## Nithiarasu pag 210 eq 7.163

    # intermediate velocities
    u_1_int = get_values(unknowns_handler, "u_1", element.connectivity)
    u_2_int = get_values(unknowns_handler, "u_2", element.connectivity)
    # these are last registered results (i.e. last time step result)
    u_1_old = get_old_values(unknowns_handler, "u_1", element.connectivity)
    u_2_old = get_old_values(unknowns_handler, "u_2", element.connectivity)
    Δu_1 = u_1_int - u_1_old
    Δu_2 = u_2_int - u_2_old
    rhs = (element.area / 3.0) * (dot(element.b, u_1_old) + dot(element.c, u_2_old))
    rhs = (element.area / 3.0) .* (element.b .* sum(Δu_1) + element.c .* sum(Δu_2)) .- rhs
    # TODO [general performance improvements]
    ## change this to the NamedTuple
    return Dict("p" => rhs) 
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepTwo, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepTwo, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end