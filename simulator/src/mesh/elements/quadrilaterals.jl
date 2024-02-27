# TODO [implement group of elements]
## for now these groups for elements are not used but they can be useful 
## to set properties for elements

"""An element of type quadrilateral"""
struct Quadrilateral <: Element
    connectivity::Vector{Int64}    
    # the derivatives
    b::Vector{Float64}
    c::Vector{Float64}
    
    # area of this element
    area::Float64
    # local time interval used for steady state simulation
    # each element has its own local time interval
    Δt::Float64
    # TODO: check if it's needed to add other properties here...
    #properties::Dict{String, Vector{Float64}}
end


"""A quadrilaterals element container"""
mutable struct QuadrilateralsContainer <: ElementsContainer
    total_elements::Int64
    nodes_per_element::Int64
    elements::Vector{Quadrilateral}
end


"""Load data for the quadrilaterals"""
function load_quadrilaterals(input_data, simulation_parameters)
    elements = Vector{Triangle}()
    # start all these values as NaN to make this break if they are not initialized
    b, c, area, Δt = NaN, NaN, NaN, NaN
    for connectivity in eachrow(input_data["mesh"]["quadrilaterals"]["connectivity"])
        append!(elements, Triangle(connectivity, b, c, area, Δt))
    end

    # set the depending on the interpolation order of the elements
    if simulation_parameters["mesh"]["interpolation_order"] == 1
        nodes_per_element = 4
    else
        throw("Higher order elements not implemented")
    end

    return TrianglesContainer(
        length(elements),
        nodes_per_element,
        elements
    )
end


"""Update properties if needed (when mesh coordinates changed)"""
function update_properties(
    elements_container::QuadrilateralsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)
    update_areas!(elements_container, nodes_container)
    update_shape_coeficients!(elements_container, nodes_container)
    update_local_time_interval!(
        elements_container, 
        nodes_container, 
        unknowns_handler,
        model_parameters.Re, 
        model_parameters.safety_dt_factor
    )
end


# TODO [implement two dimensional elements]
"""Calculate and update areas of quadrilaterals"""
function update_areas!(
    elements_container::QuadrilateralsContainer, nodes_container::NodesContainer
)
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function update_shape_coeficients!(
    elements_container::QuadrilateralsContainer, nodes_container::NodesContainer
)
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
"""Update values of local time step intervals for steady state simulations"""
function update_local_time_interval!(
    elements_container::QuadrilateralsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    Re::Float64,
    safety_factor::Float64
)    
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function calculate_specific_sizes(
    element::Quadrilateral, nodes_container::NodesContainer
)
    return 0.0
end
