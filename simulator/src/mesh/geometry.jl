"""Calculate length given the nodes ids of the edge endings"""
function calculate_length(nodes_ids::Vector{Int64}, nodes::NodesContainer)
    x = get_positions_x(nodes, nodes_ids)
    y = get_positions_y(nodes, nodes_ids)
    return sqrt((x[1] - x[2])^2 + (y[1] - y[2])^2)
end

"""Calculate length for an segment"""
function calculate_length(element::Segment, nodes::NodesContainer)
    x = get_positions_x(nodes, get_border_node_ids(element))
    return abs(x[1] - x[2])
end


"""Calculate area for an triangle"""
function calculate_area(element::Triangle, nodes::NodesContainer)
    x = get_positions_x(nodes, get_border_node_ids(element))
    y = get_positions_y(nodes, get_border_node_ids(element))
    return 0.5 * abs((x[2] - x[1]) * (y[3] - y[1]) - (x[3] - x[1]) * (y[2] - y[1]))
end


# TODO [implement one dimensional elements]
# TODO [implement two dimensional elements]
# TODO [implement three dimensional elements]