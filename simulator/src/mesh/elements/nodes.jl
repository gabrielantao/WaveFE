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
    total_nodes::Int64
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
        eachrow(input_data["mesh"]["nodes"]["physical_groups"]),
        eachrow(input_data["mesh"]["nodes"]["geometrical_groups"]),
        eachrow(input_data["mesh"]["nodes"]["domain_condition_groups"]),
        eachrow(input_data["mesh"]["nodes"]["positions"]),
        eachrow(input_data["mesh"]["nodes"]["velocities"]),
        eachrow(input_data["mesh"]["nodes"]["accelerations"]),
        )
        append!(
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
        input_data["mesh"]["nodes"]["total_nodes"],
        nodes,
        moved
    )
end


"""Convinience function to get the list of x positions for node ids"""
function get_positions_x(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[1] for node_id in nodes_ids]
end


"""Convinience function to get the list of y positions for node ids"""
function get_positions_y(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[2] for node_id in nodes_ids]
end


"""Convinience function to get the list of z positions for node ids"""
function get_positions_z(nodes::NodesContainer, nodes_ids::Vector{Int64})
    return [nodes.series[node_id].position[3] for node_id in nodes_ids]
end


function get_domain_condition_groups(nodes::NodesContainer)
    return [node.domain_condition_groupfor node in nodes.series]
end

# TODO [implement mesh movement]
# in the future this function could be implemented in another 
# file to define the rule for the movement
"""Do the movement for the nodes"""
function move!(nodes::NodesContainer)
    nodes.moved = False
end 