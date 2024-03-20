# exported entities
export Quadrilateral, QuadrilateralsContainer


"""An element of type quadrilateral"""
mutable struct Quadrilateral <: Element
    connectivity::Vector{Int64}    
    # the derivatives
    b::Vector{Float64}
    c::Vector{Float64}
    
    # area of this element
    area::Float64
    # local time interval used for steady state simulation
    # each element has its own local time interval
    Δt::Float64
    # TODO [review elements specific properties]
    ## check if it's needed to add other properties here...
    ## properties::Dict{String, Vector{Float64}}
end


"""A quadrilaterals element container"""
mutable struct QuadrilateralsContainer <: ElementsContainer
    name::String
    nodes_per_element::Int64
    series::Vector{Quadrilateral}
    # TODO [implement group of elements]
    ## for now these groups for elements are not used but they can be useful 
    ## to set properties for elements
end


"""Load data for the quadrilaterals"""
function load_quadrilaterals(mesh_data::MeshData)
    elements = Vector{Quadrilateral}()
    nodes_per_element = 4
    for elements_data in mesh_data.elements
        if elements_data.element_type_data.type == QUADRILATERAL::ElementType
            for connectivity in eachcol(elements_data.connectivity)
                # start all these values as NaN to make this break if they are not initialized
                push!(elements, Quadrilateral(connectivity, Float64[], Float64[], NaN, NaN))
                nodes_per_element = elements.element_type_data.nodes_per_element
            end
            nodes_per_element = elements_data.element_type_data.nodes_per_element
        end
    end
    return QuadrilateralsContainer(
        "quadrilaterals",
        nodes_per_element,
        elements
    )
end


"""Update properties if needed (when mesh coordinates changed)"""
function update_properties!(
    elements_container::QuadrilateralsContainer, 
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


# TODO [implement two dimensional elements]
"""Calculate and update areas of quadrilaterals"""
function update_areas!(
    elements_container::QuadrilateralsContainer, 
    nodes_container::NodesContainer
)
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function update_shape_coeficients!(
    elements_container::QuadrilateralsContainer, 
    nodes_container::NodesContainer
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
    safety_Δt_factor::Float64
)    
end


# TODO [implement two dimensional elements]
# TODO [implement higher order elements]
function calculate_specific_sizes(
    element::Quadrilateral, nodes_container::NodesContainer
)
    return 0.0
end
