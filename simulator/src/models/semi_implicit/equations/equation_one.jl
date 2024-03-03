"""The first equation of the model semi-implicit"""
struct EquationStepOne <: Equation
    # common data ("base class" data)
    base::BaseModelEquation
    # if the assembler should use the diagonal matrix for the elements
    use_lumped_mass::Bool
    # the safety_dt_factor used to calculate local Δt for the elements
    safety_dt_factor::Float64

    function EquationStepOne(solved_unknowns, simulation_parameters)   
        # TODO: this should be in a section model in the input file
        use_lumped_mass = !simulation_parameters["simulation"]["transient"]
        safety_dt_factor = simulation_parameters["simulation"]["safety_dt_factor"]
        lhs_type = use_lumped_mass ? WaveCore.DIAGONAL::MatrixType : WaveCore.SYMMETRIC::MatrixType
        assembler = Assembler(lhs_type)
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


# TODO [implement one dimensional elements]
# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepOne, 
    element::Segment, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters

)
    throw("Not implemented unidimensional elements assembling")
end


# TODO [implement one dimensional elements]
# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepOne, 
    element::Segment, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented unidimensional elements assembling")
end


# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepOne, 
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


# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepOne, 
    element::Triangle, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    # TODO [review the equation formulations]
    # TODO [implement one dimensional elements]
    # TODO [implement three dimensional elements]
    ## check forcing vectors in this assembling process
    ## Nithiarasu pag 210 eq 7.161, 7.162

    Re = model_parameters.adimensionals["Re"]
    # calculate momentum convection term
    u_1 = get_values(unknowns_handler, "u_1", element.connectivity)
    u_2 = get_values(unknowns_handler, "u_2", element.connectivity)
    u_1_sum = sum(u_1)
    u_2_sum = sum(u_2)
    # ((2.0 * area) * (1 / 24.0)) .* ((u_1_sum .+ u_1) * b' + (u_2_sum .+ u_2) * c') 
    C_e = (element.area / 12.0) .* ((u_1_sum .+ u_1) * element.b' + (u_2_sum .+ u_2) * element.c') 
    
    # calculate momentum diffusion term
    Km_e =  (element.area / Re) .* (element.b * element.b' + element.c * element.c')
    
    # calculate momentum stabilization term
    Ks  = mean(u_1) .* (sum(u_1) .* (element.b * element.b') + sum(u_2) .* (element.b * element.c'))
    Ks += mean(u_2) .* (sum(u_1) .* (element.c * element.b') + sum(u_2) .* (element.c * element.c'))
    # ((2.0 * area) * (dt / 2.0) / 6.0) .* Ks
    Ks_e = ((element.Δt / 2.0) * (element.area / 3.0)) .* Ks

    # TODO [general performance improvements]
    ## change this to the NamedTuple
    return Dict(
        "u_1" => -(C_e + Km_e + Ks_e) * u_1, 
        "u_2" => -(C_e + Km_e + Ks_e) * u_2
    )
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function assemble_element_lhs(
    equation::EquationStepOne, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function assemble_element_rhs(
    equation::EquationStepOne, 
    element::Quadrilateral, 
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelSemiImplicitParameters
)
    throw("Not implemented bidimensional elements assembling")
end
