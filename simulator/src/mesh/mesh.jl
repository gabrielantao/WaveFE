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
    # real adimensional time steps for transient problems
    Δt::Vector{Float64}
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
        must_refresh,
        Vector{Float64}()
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


"""Get the minimum values of timestep for all elements in the mesh"""
function get_minimum_timestep_interval(mesh::Mesh)
    return minimum([element_container.Δt_min for element_container in get_containers(mesh.elements)])
end


"""Update the timestep intervals for the elements in the container to a given value"""
function update_global_timestep_intervals!(element_container::ElementsContainer, Δt::Float64)
    for element in get_elements(element_container)
        element.Δt = Δt
    end
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
            model_parameters,
            mesh.must_refresh || mesh.nodes.moved
        ) 
    end
end


"""
Update the global time step interval for each element.
There are two modes: local time step and global time step.
- global time step: used when the proble is set as transient=true, when the transient effects matter
- local time step: used when the proble is set as transient=false, for steady state problem when only final state matters.
  do nothing if local time step is used i.e. just use the local time steps previously calculated
"""
function update_time_interval!(mesh::Mesh, transient::Bool)
    if transient
        Δt_min = get_minimum_timestep_interval(mesh)
        for element_container in get_containers(mesh.elements)
            update_global_timestep_intervals!(element_container, Δt_min)
        end
        # add the current time step interval to the intervals list
        push!(mesh.Δt, Δt_min)
    end
end


# TODO [implement mesh movement]
"""Update the mesh i.e. remesh if needed and move the nodes"""
function update!(mesh::Mesh)
    mesh.must_refresh = false
    move!(mesh.nodes)
end