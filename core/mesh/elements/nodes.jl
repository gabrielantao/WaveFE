struct Node
    # physical group used internally by the models 
    # (e.g. to set properties for elements)
    physical_group::Int32
    # geometrical group used internally by the models 
    # (e.g. to move group of elements) 
    geometrical_group::Int32
    # groups used to defined domain conditions
    domain_condition_group::Int32
    
    # kinematics properties
    position::Vector{Float64}
    velocitie::Vector{Float64}
    acceleration::Vector{Float64}
end


"""This is a container for the nodes in the mesh"""
mutable struct NodesContainer
    total_nodes::Int32
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
function get_positions_x(nodes::NodesContainer, nodes_ids::Vector{Int32})
    return [nodes.series[node_id].position[1] for node_id in nodes_ids]
end


"""Convinience function to get the list of y positions for node ids"""
function get_positions_y(nodes::NodesContainer, nodes_ids::Vector{Int32})
    return [nodes.series[node_id].position[2] for node_id in nodes_ids]
end


"""Convinience function to get the list of z positions for node ids"""
function get_positions_z(nodes::NodesContainer, nodes_ids::Vector{Int32})
    return [nodes.series[node_id].position[3] for node_id in nodes_ids]
end


function move!(nodes::ContainerNodes)
    nodes.moved = False
    # TODO: implement movement of the mesh based in some function of movement for
    #       the specific groups that must move.
end 