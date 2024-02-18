# TODO: this should be a module (???)


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
end


"""Import a mesh from files in cache path."""
function load_mesh(input_data, simulation_parameters)
    nodes = load_nodes(input_data)
    if input_data["mesh"]["dimension"] == 1 
        dimension = UNIDIMENSIONAL
        elements = UniDimensionalElements(
            load_segments(input_data)
        )
    elseif input_data["mesh"]["dimension"] == 2
        dimension = BIDIMENSIONAL
        elements = BiDimensionalElements(
            load_triangles(input_data), 
            load_quadrilaterals(input_data)
        )
    elseif input_data["mesh"]["dimension"] == 3
        dimension = TRIDIMENSIONAL
        # TODO: implement here the tridimensional elements
    end

    return Mesh(
        dimension, 
        nodes, 
        elements
    )
end


"""Function to return reference to the elements containers used for the mesh"""
function get_containers(mesh::Mesh)
    if mesh.dimension == UNIDIMENSIONAL
        return [mesh.elements.segments]
    elseif mesh.dimension == BIDIMENSIONAL
        return [mesh.elements.triangles, mesh.elements.quadrilaterals]
    elseif mesh.dimension  == TRIDIMENSIONAL
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
     # logger.info(
        #     "update the element parameters, geometry, delta time and shape factors"
        # )
    for element_container in get_containers(mesh)
        update_properties!(
            element_container, 
            nodes_container,
            unknowns_handler,
            model_parameters
        ) 
    end
end
