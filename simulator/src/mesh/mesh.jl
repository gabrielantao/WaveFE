# exported entities
export Mesh

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

    # if the mesh was refreshed (remeshed)
    # this can trigger the assembler redo:
    # - the preallocation for the matrices
    must_refresh::Bool
end


"""Import a mesh from files in cache path."""
function build_mesh(mesh_data::MeshData)
    # initially it need to be set to refresh to force the
    # first calculations that depend on this 
    must_refresh = true
    nodes = load_nodes(mesh_data)
    # get the dimension of the mesh
    if mesh_data.dimension == UNIDIMENSIONAL::Dimension
        elements = UniDimensionalElements(
            load_segments(mesh_data)
        )
    elseif mesh_data.dimension == BIDIMENSIONAL::Dimension
        elements = BiDimensionalElements(
            load_triangles(mesh_data), 
            load_quadrilaterals(mesh_data)
        )
    elseif mesh_data.dimension == TRIDIMENSIONAL::Dimension
        # TODO [implement three dimensional elements]
        throw("Not implemented tridimensional elements")
    end

    return Mesh(
        mesh_data.dimension, 
        nodes, 
        elements,
        must_refresh
    )
end


"""Function to return reference to the elements containers used for the mesh"""
function get_containers(mesh_elements::UniDimensionalElements)
    return [mesh_elements.segments]
end


"""Function to return reference to the elements containers used for the mesh"""
function get_containers(mesh_elements::BiDimensionalElements)
    containers = Vector{ElementsContainer}()
    for element_container in [mesh_elements.triangles, mesh_elements.quadrilaterals]
        if has_elements(element_container)
            push!(containers, element_container)
        end
    end
    return containers
end


function has_elements(element_container::ElementsContainer)
    return get_total_elements(element_container) > 0
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


"""Return the elements in the container"""
function get_elements(element_container::ElementsContainer)
    return element_container.series
end


"""Get the connectivity matrix for all elements in a container"""
function get_connectivity_matrix(element_container::ElementsContainer)
    return reduce(hcat, [element.connectivity for element in get_elements(element_container)])
end


"""Update the elements calculated properties"""
function update_elements!(
    mesh::Mesh,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)
    # it must be updated every timestep regardless mesh updated or nodes moved
    for element_container in get_containers(mesh.elements)
        update_properties!(
            element_container, 
            mesh.nodes,
            unknowns_handler,
            model_parameters
        ) 
    end
end


# TODO [implement mesh movement]
"""Update the mesh i.e. remesh if needed and move the nodes"""
function update!(mesh::Mesh)
    mesh.must_refresh = false
    move!(mesh.nodes)
end