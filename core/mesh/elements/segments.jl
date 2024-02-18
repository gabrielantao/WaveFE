"""An element of type segment"""
struct Segment <: Element
    connectivity::Vector{Int32}      
    # the derivatives
    b::Vector{Float64}
    c::Vector{Float64}
    
    # area of this element
    length::Float64
    # local time interval used for steady state simulation
    # each element has its own local time interval
    Δt::Float64
    # TODO: check if it's needed to add other properties here...
    #properties::Dict{String, Vector{Float64}}
end


"""An segment element group"""
mutable struct SegmentsContainer <: ElementsContainer
    total_elements::Int32
    elements::Vector{Triangle}
end


"""Load data for the segments"""
function load_segments(input_data)
    elements = Vector{Triangle}()
    # start all these values as NaN to make this break if they are not initialized
    b, c, length, Δt = NaN, NaN, NaN, NaN
    for connectivity in eachrow(input_data["mesh"]["segments"]["connectivity"])
        append!(elements, Segment(connectivity, b, c, length, Δt))
    end
    return SegmentsContainer(
        input_data["mesh"]["segments"]["total_elements"]
        elements
    )
end


# TODO: implement this function
"""Update properties when needed"""
function update_properties(
    elements_container::SegmentsContainer, 
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
"""Calculate and update lengths of segments"""
function update_lengths!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer
)
end


# TODO: implement this function
function update_shape_coeficients!(
    elements_container::SegmentsContainer, nodes_container::NodesContainer
)
end

# TODO: implement this function
"""Update values of local time step intervals for steady state simulations"""
function update_local_time_interval!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    Re::Float64,
    safety_factor::Float64
)    
end

# TODO: implement this function
function calculate_specific_sizes(
    element::Segment, nodes_container::NodesContainer
)
    return 0.0
end

