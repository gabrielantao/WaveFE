"""An element of type triangle"""
struct Triangle <: Element
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


"""A triangle element container"""
mutable struct TrianglesContainer <: ElementsContainer
    total_elements::Int32
    elements::Vector{Triangle}
end


"""Load data for the triangles"""
function load_triangles(input_data)
    elements = Vector{Triangle}()
    # start all these values as NaN to make this break if they are not initialized
    b, c, area, Δt = NaN, NaN, NaN, NaN
    for connectivity in eachrow(input_data["mesh"]["triangles"]["connectivity"])
        append!(elements, Triangle(connectivity, b, c, area, Δt))
    end
    return TrianglesContainer(
        input_data["mesh"]["triangles"]["total_elements"]
        elements
    )
end


"""
Get the border nodes ids of an element.
Since a higher order element could have more elements this should be used to get
only the nodes in the endings of the element.
"""
function get_border_node_ids(element::Triangle)
    return element.connectivity[1:3]
end


"""Get the edges nodes ids of an element."""
function get_edges_node_ids(element::Triangle)
    return [
        [element.connectivity[1] element.connectivity[2]], 
        [element.connectivity[2] element.connectivity[3]],
        [element.connectivity[3] element.connectivity[1]]
    ]
end


"""Update properties when needed."""
function update_properties!(
    elements_container::TrianglesContainer, 
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


"""Calculate and update areas of triangles."""
function update_areas!(
    elements_container::TrianglesContainer, 
    nodes_container::NodesContainer
)
    for element in elements_container
        element.area = calculate_area(element, nodes_container)
    end
end


# TODO: check if this coeficients are different depending on interpolation order...
"""Update triangle element shape coeficients."""
function update_shape_coeficients!(
    elements_container::TrianglesContainer, 
    nodes_container::NodesContainer
)
    for element in elements_container
        x = get_positions_x(nodes_container, get_border_node_ids(element))
        y = get_positions_y(nodes_container, get_border_node_ids(element))
        # divide by (2.0 * area) to adimensionalize
        element.b = [y[2] - y[3], y[3] - y[1], y[1] - y[2]] / (2.0 * element.area)
        element.c = [x[3] - x[2], x[1] - x[3], x[2] - x[1]] / (2.0 * element.area)
    end
end


"""Update values of local time step intervals for steady state simulations."""
function update_local_time_interval!(
    elements_container::TrianglesContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    Re::Float64,
    safety_factor::Float64
)    
    # get the velocities moduli
    velocities = sqrt.(unknowns_handler.values["u_1"] .^2 + unknowns_handler.values["u_2"] .^2)
    for element in elements_container
        h = calculate_specific_sizes(element, nodes_container)
        max_velocity = maximum(velocities[element.connectivity])
        element.Δt = safety_factor * min((Re / 2.0) * h^2, h / max_velocity)
    end 
end


"""
This updates specific sizes.
(see Nithiarasu eq 7.128 for a nodal version)
"""
function calculate_specific_sizes(
    element::Triangle, 
    nodes_container::NodesContainer
)
    length = 0.0
    for node_ids in get_edges_node_ids(element)
        length = max(length, calculate_length(node_ids, nodes_container))
    end
    return 2.0 * element.area / length
end
