# exported entities
export Mesh
export InterpolationOrder, Dimension


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
include("./elements/nodes.jl")
include("./elements/segments.jl")
include("./elements/triangles.jl")
include("./elements/quadrilaterals.jl")
include("./geometry.jl")


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


# TODO [implement three dimensional elements]
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
function load_mesh(input_data, simulation_data)
    nodes = load_nodes(input_data)
    # get the dimension of the mesh
    if read(input_data["mesh/dimension"]) == 1
        dimension = UNIDIMENSIONAL::Dimension
        elements = UniDimensionalElements(
            load_segments(input_data, simulation_data)
        )
    elseif read(input_data["mesh/dimension"]) == 2
        dimension = BIDIMENSIONAL::Dimension
        elements = BiDimensionalElements(
            load_triangles(input_data, simulation_data), 
            load_quadrilaterals(input_data, simulation_data)
        )
    elseif read(input_data["mesh/dimension"]) == 3
        dimension = TRIDIMENSIONAL::Dimension
        # TODO [implement three dimensional elements]
        throw("Not implemented tridimensional elements")
    end
    # get the interpolation order for the mesh
    if simulation_data["mesh"]["interpolation_order"] == 1
        interpolation_order = ORDER_ONE::InterpolationOrder
    elseif simulation_data["mesh"]["interpolation_order"] == 2
        interpolation_order = ORDER_TWO::InterpolationOrder
    elseif simulation_data["mesh"]["interpolation_order"] == 3
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
function get_containers(mesh_elements::UniDimensionalElements)
    return [mesh_elements.segments]
end


"""Function to return reference to the elements containers used for the mesh"""
function get_containers(mesh_elements::BiDimensionalElements)
    return [mesh_elements.triangles, mesh_elements.quadrilaterals]
end


# TODO [implement three dimensional elements]
# """Function to return reference to the elements containers used for the mesh"""
# function get_containers(mesh_elements::TriDimensionalElements)
#     return []
# end


"""Return the total of elements in the container"""
function get_total_elements(element_container::ElementsContainer)
    return length(element_container.series)
end


"""Update (move) mesh nodes when a dynamic mesh is used"""
function update_elements!(
    mesh::Mesh,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)
    if mesh.must_refresh || mesh.nodes.moved
        for element_container in get_containers(mesh.elements)
            update_properties!(
                element_container, 
                mesh.nodes,
                unknowns_handler,
                model_parameters
            ) 
        end
    end
end


# TODO [implement mesh movement]
"""Update the mesh i.e. remesh if needed and move the nodes"""
function update!(mesh::Mesh)
    mesh.must_refresh = false
    move!(mesh.nodes)
end