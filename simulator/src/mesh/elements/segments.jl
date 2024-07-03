# exported entities
export Segment, SegmentsContainer


"""An element of type segment"""
mutable struct Segment <: Element
    connectivity::Vector{Int64}      
    # the derivatives
    b::Vector{Float64}
    c::Vector{Float64}
    
    # area of this element
    length::Float64
    # local time interval used for steady state simulation
    # each element has its own local time interval
    Δt::Float64
    # TODO [review elements specific properties]
    ## check if it's needed to add other properties here...
    ## properties::Dict{String, Vector{Float64}}
end


"""An segment element group"""
mutable struct SegmentsContainer <: ElementsContainer
    name::String
    nodes_per_element::Int64
    series::Vector{Segment}
    Δt_min::Float64
    # TODO [implement group of elements]
    ## for now these groups for elements are not used but they can be useful 
    ## to set properties for elements
end


"""Load data for the segments"""
function load_segments(mesh_data::MeshData)
    elements = Vector{Segment}()
    nodes_per_element = 2
    for elements_data in mesh_data.elements
        if elements_data.element_type_data.type == SEGMENT::ElementType
            for connectivity in eachcol(elements_data.connectivity)
                # start all these values as NaN to make this break if they are not initialized
                push!(elements, Segment(connectivity, Float64[], Float64[], NaN, NaN))
            end
            nodes_per_element = elements_data.element_type_data.nodes_per_element
        end
    end
    return SegmentsContainer(
        "segments",
        nodes_per_element,
        elements,
        Inf
    )
end


# TODO [implement segment elements]
"""Update properties when needed"""
function update_properties!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters,
    must_update_geometry::Bool
)
    if must_update_geometry
        update_areas!(elements_container, nodes_container)
        update_shape_coeficients!(elements_container, nodes_container)
    end
    
    update_local_time_interval!(
        elements_container, 
        nodes_container, 
        unknowns_handler,
        model_parameters.adimensionals["Re"], 
        model_parameters.safety_Δt_factor 
    )
end


# TODO [implement segment elements]
"""Calculate and update lengths of segments"""
function update_lengths!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer
)
end


# TODO [implement segment elements]
# TODO [implement higher order bidimensional elements]
function update_shape_coeficients!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer
)
end

# TODO [implement segment elements]
# TODO [implement higher order bidimensional elements]
"""Update values of local time step intervals for steady state simulations"""
function update_local_time_interval!(
    elements_container::SegmentsContainer, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    Re::Float64,
    safety_Δt_factor::Float64
)    
end

# TODO [implement segment elements]
# TODO [implement higher order bidimensional elements]
function calculate_specific_sizes(
    element::Segment, nodes_container::NodesContainer
)
    return 0.0
end

