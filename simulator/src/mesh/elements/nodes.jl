# exported entities
export Node, NodesContainer


struct Node
    # physical group used internally by the models 
    # (e.g. to set properties for elements)
    physical_group::Int64
    # geometrical group used internally by the models 
    # (e.g. to move group of elements) 
    geometrical_group::Int64
    # groups used to defined domain conditions
    domain_condition_group::Int64
    
    # kinematics properties
    position::Vector{Float64}
    velocity::Vector{Float64}
    acceleration::Vector{Float64}
end


"""This is a container for the nodes in the mesh"""
mutable struct NodesContainer
    series::Vector{Node}
    moved::Bool
end


"""Import data for nodes."""
function load_nodes(input_data)
    nodes = Vector{Node}()
    for (
        physical_group, 
        geometrical_group, 
        domain_condition_group, 
        position, 
        velocity, 
        acceleration
        ) in zip(
        read(input_data["mesh/nodes/physical_groups"]),
        read(input_data["mesh/nodes/geometrical_groups"]),
        read(input_data["mesh/nodes/domain_condition_groups"]),
        eachcol(read(input_data["mesh/nodes/positions"])),
        eachcol(read(input_data["mesh/nodes/velocities"])),
        eachcol(read(input_data["mesh/nodes/accelerations"])),
        )
        push!(
            nodes,
            Node(
                physical_group,
                geometrical_group,
                domain_condition_group,
                position,
                velocity,
                acceleration,
            )
        )
    end
    # start moved variable as true to force the update of mesh parameters 
    # at the first time step
    moved = true
    return NodesContainer(
        nodes,
        moved
    )
end


"""Return the total of nodes in the container"""
function get_total_nodes(nodes_container::NodesContainer)
    return length(nodes_container.series)
end


"""Return the total of nodes in the container"""
function get_nodes(nodes_container::NodesContainer)
    return nodes_container.series
end


"""Convinience function to get the list of x positions for node ids"""
function get_positions_x(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[1] for node_id in nodes_ids]
end


"""
Convinience function to get the list of y positions for node ids
NOTE: this internally is going to break if one try to call this in a unidimensional mesh    
"""
function get_positions_y(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[2] for node_id in nodes_ids]
end


"""
Convinience function to get the list of z positions for node ids
NOTE: this internally is going to break if one try to call this in a uni- or bidimensionalmesh 
"""
function get_positions_z(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[3] for node_id in nodes_ids]
end


"""Get the vector with domain conditions list for all nodes"""
function get_domain_condition_groups(nodes::NodesContainer)
    return [node.domain_condition_group for node in nodes.series]
end


# TODO [implement mesh movement]
# in the future this function could be implemented in another 
# file to define the rule for the movement
"""Do the movement for the nodes"""
function move!(nodes::NodesContainer)
    nodes.moved = false
end 