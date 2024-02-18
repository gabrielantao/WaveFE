"""An element of type quadrilateral"""
struct Quadrilateral <: Element
    connectivity::Vector{Int32}    
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
    total_elements::Int32
    elements::Vector{Quadrilateral}
end


"""Load data for the quadrilaterals"""
function load_quadrilaterals(input_data)
    elements = Vector{Triangle}()
    # start all these values as NaN to make this break if they are not initialized
    b, c, area, Δt = NaN, NaN, NaN, NaN
    for connectivity in eachrow(input_data["mesh"]["quadrilaterals"]["connectivity"])
        append!(elements, Triangle(connectivity, b, c, area, Δt))
    end
    return TrianglesContainer(
        input_data["mesh"]["quadrilaterals"]["total_elements"]
        elements
    )
end


# TODO: implement this function
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


# TODO: implement this function
"""Calculate and update areas of quadrilaterals"""
function update_areas!(
    elements_container::QuadrilateralsContainer, nodes_container::NodesContainer
)
end


# TODO: implement this function
function update_shape_coeficients!(
    elements_container::QuadrilateralsContainer, nodes_container::NodesContainer
)
end


# TODO: implement this function
"""Update values of local time step intervals for steady state simulations"""
function update_local_time_interval!(
    elements_container::QuadrilateralsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    Re::Float64,
    safety_factor::Float64
)    
end


# TODO: implement this function
function calculate_specific_sizes(
    element::Quadrilateral, nodes_container::NodesContainer
)
    return 0.0
end
