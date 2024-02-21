# the abstract types used in this module...
"""A generic single element"""
abstract type Element end 

"""A generic container that groups the elements"""
abstract type ElementsContainer end

"""
A generic element container that groups containers 
depending on the dimension of the mesh
"""
abstract type ElementsSet end

# include files for the elements and containers 
include("./geometry.jl")
include("./elements/nodes.jl")
include("./elements/segments.jl")
include("./elements/triangles.jl")
include("./elements/quadrilaterals.jl")


@enum InterpolationOrder begin
    ORDER_ONE = 1
    ORDER_TWO = 2
    ORDER_THREE = 3
end


@enum Dimension begin
    UNIDIMENSIONAL = 1
    BIDIMENSIONAL = 2
    TRIDIMENSIONAL = 3
end


"""This struct group the elements for a unidimension mesh"""
mutable struct UniDimensionalElements <: ElementsSet
    segments::SegmentsContainer
end


"""This struct group the elements for a two dimensions mesh"""
mutable struct BiDimensionalElements <: ElementsSet
    triangles::TrianglesContainer
    quadrilaterals::QuadrilateralsContainer
end


# TODO: implement it here
# mutable struct TriDimensionalElements <: ElementsSet
# end


"""A mesh struct to keep element data."""
mutable struct Mesh
    dimension::Dimension
    nodes::NodesContainer
    elements::ElementsSet
    interpolation_order::InterpolationOrder

    # if the mesh was refreshed (remeshed)
    # this can trigger the assembler redo:
    # - the preallocation for the matrices
    must_refresh::Bool
end


"""Import a mesh from files in cache path."""
function load_mesh(input_data, simulation_parameters)
    nodes = load_nodes(input_data)
    # get the dimension of the mesh
    if input_data["mesh"]["dimension"] == 1 
        dimension = UNIDIMENSIONAL::Dimension
        elements = UniDimensionalElements(
            load_segments(input_data)
        )
    elseif input_data["mesh"]["dimension"] == 2
        dimension = BIDIMENSIONAL::Dimension
        elements = BiDimensionalElements(
            load_triangles(input_data), 
            load_quadrilaterals(input_data)
        )
    elseif input_data["mesh"]["dimension"] == 3
        dimension = TRIDIMENSIONAL::Dimension
        # TODO: implement here the tridimensional elements
    end
    # get the interpolation order for the mesh
    if simulation_parameters["mesh"]["interpolation_order"] == 1
        interpolation_order = ORDER_ONE::InterpolationOrder
    elseif simulation_parameters["mesh"]["interpolation_order"] == 2
        interpolation_order = ORDER_TWO::InterpolationOrder
    elseif simulation_parameters["mesh"]["interpolation_order"] == 3
        interpolation_order = ORDER_THREE::InterpolationOrder
    end
    # initially it need to be set to refresh to force the
    # first calculations that depend on this 
    must_refresh = true

    return Mesh(
        dimension, 
        nodes, 
        elements,
        interpolation_order,
        must_refresh
    )
end


"""Function to return reference to the elements containers used for the mesh"""
function get_containers(mesh::Mesh)
    if mesh.dimension == UNIDIMENSIONAL::Dimension
        return [mesh.elements.segments]
    elseif mesh.dimension == BIDIMENSIONAL::Dimension
        return [mesh.elements.triangles, mesh.elements.quadrilaterals]
    elseif mesh.dimension  == TRIDIMENSIONAL::Dimension
        throw("Not supported for tridimensional elements yet.")
    end
end


"""Update (move) mesh nodes when a dynamic mesh is used"""
function update_elements!(
    mesh::Mesh, 
    nodes_container::NodesContainer,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
    )
    for element_container in get_containers(mesh)
        update_properties!(
            element_container, 
            nodes_container,
            unknowns_handler,
            model_parameters
        ) 
    end
end


function update!(mesh::Mesh)
    # TODO: implement here the logic if in future the mesh must be redone
    mesh.must_refresh = false
    move!(mesh.nodes)
end