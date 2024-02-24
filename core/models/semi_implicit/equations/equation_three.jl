"""The first equation of the model semi-implicit"""
struct EquationStepThree <: Equation
    # common data ("base class" data)
    base::BaseModelEquation
    # if the assembler should use the diagonal matrix for the elements
    use_lumped_mass::Bool
    # the safety_dt_factor used to calculate local Δt for the elements
    safety_dt_factor::Float64

    function EquationStepThree(solved_unknowns, simulation_parameters)   
        # TODO: this should be in a section model in the input file
        use_lumped_mass = !simulation_parameters["simulation"]["transient"]
        safety_dt_factor = simulation_parameters["simulation"]["safety_dt_factor"]
        lhs_type = use_lumped_mass ? DIAGONAL : SYMMETRIC
        assembler = Assembler(lhs_type)
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
function assemble_element_lhs(
    equation::EquationStepThree, 
    element::Segment, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented unidimensional elements assembling")
end


function assemble_element_rhs(
    equation::EquationStepThree, 
    element::Segment, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented unidimensional elements assembling")
end


function assemble_element_lhs(
    equation::EquationStepThree, 
    element::Triangle, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    nodes_per_element = length(element.connectivity)
    if equation.use_lumped_mass
        return sparse(
            1:nodes_per_element,
            1:nodes_per_element,
            fill(element.area / element.Δt / 3.0, nodes_per_element)
        )
    else
        # TODO [implement mass matrix not lumped]
        ## check if this is correct then implement it
        ## (element.area / 12.0 / element.Δt) .* [2.0 1.0 1.0; 1.0 2.0 1.0; 1.0 1.0 2.0]
        throw("Not implemented not lumped mass matrix!")
    end
end


# TODO [review symmetric matrix assembling]
## it don't need to be assembled the dense matrix for the element
# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepThree, 
    element::Triangle, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    # pressure
    p = get_values(unknowns_handler, "p", element.connectivity)
    p_old = get_old_values(unknowns_handler, "p", element.connectivity)
    # these are last registered results (i.e. last time step result)
    u_1_old = get_old_values(unknowns_handler, "u_1", element.connectivity)
    u_2_old = get_old_values(unknowns_handler, "u_2", element.connectivity)
    # calculate gradients and use mean velocity for computations
    grad_1 = (element.area / 3.0) * dot(element.b, p)
    grad_2 = (element.area / 3.0) * dot(element.c, p)
    grad_1_old = (element.area * element.Δt / 2.0) * dot(element.b, p_old)
    grad_2_old = (element.area * element.Δt / 2.0) * dot(element.c, p_old)
    # TODO [general performance improvements]
    ## change this to the NamedTuple
    return Dict(
        "u_1" => -(grad_1 .+ (element.b .* mean(u_1_old) + element.c .* mean(u_2_old)) .* grad_1_old), 
        "u_2" => -(grad_2 .+ (element.b .* mean(u_1_old) + element.c .* mean(u_2_old)) .* grad_2_old)
    )
end


# TODO [implement two dimensional elements]
function assemble_element_lhs(
    equation::EquationStepThree, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end


# TODO [implement two dimensional elements]
function assemble_element_rhs(
    equation::EquationStepThree, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end