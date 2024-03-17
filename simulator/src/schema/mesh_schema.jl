struct GeometricalGroupsData
    names::Dict{Int64, String}
    groups::Vector{Int64}
end


struct PhysicalGroupsData
    names::Dict{Int64, String}
    groups::Vector{Int64}
end


struct NodeData
    total_nodes::Int64
    positions::Matrix{Float64}
    geometrical_groups::GeometricalGroupsData
    physical_groups::PhysicalGroupsData
end


struct ElementTypeData
    name::String
    type::ElementType
    dimension::Dimension
    interpolation_order::InterpolationOrder
    nodes_per_element::Int64
    local_coordinates::Vector{Float64}
end


struct ElementsData
    element_type_data::ElementTypeData
    total_elements::Int64
    connectivity::Matrix{Int64}
end


struct MeshData
    dimension::Dimension
    nodes::NodeData
    elements::Vector{ElementsData}
end


"""Get data from the mesh file"""
function load_mesh_data(mesh_filepath::String)
    # ensure the file exists otherwise Gmsh assumes we want to start a new model
    if !isfile(mesh_filepath)
        throw("The mesh file does not exist:\n$mesh_filepath")
    end

    Gmsh.gmsh.initialize()
    Gmsh.gmsh.open(mesh_filepath)
    dimension = Int64(Gmsh.gmsh.model.getDimension())
    if splitext(mesh_filepath)[1] == ".geo"
        Gmsh.gmsh.option.setNumber("Mesh.SaveAll", 1)
        Gmsh.gmsh.model.mesh.generate(dimension)
    end

    Gmsh.gmsh.model.mesh.renumberNodes()
    Gmsh.gmsh.model.mesh.renumberElements()

    # get nodes and elements
    nodes = load_nodes_data()
    elements = load_elements_data(dimension) 

    Gmsh.gmsh.finalize()
    return MeshData(
        get_dimension_number(dimension),
        nodes,
        elements,
    )
end


"""Convert data for the Gmsh element type into a ElementData struct"""
function parse_element_type_data(element_type)
    properties = Gmsh.gmsh.model.mesh.getElementProperties(element_type)
    name = properties[1]
    return ElementTypeData(
        name,
        get_element_type(name),
        get_dimension_number(properties[2]), 
        get_interpolation_order(properties[3]),
        Int64(properties[4]),
        properties[5]
    )
end


"""Get data for the nodes groups"""
function load_nodes_data()
    _, positions, _ = Gmsh.gmsh.model.mesh.getNodes()
    # the Gmsh API returns a multiple of 3 when importing the nodes positions
    # so it must assert if this is always true
    GMSH_DEFAULT_DIMENSION = 3
    @assert length(positions) % GMSH_DEFAULT_DIMENSION == 0
    positions = reshape(positions, (GMSH_DEFAULT_DIMENSION, :))
    total_nodes = size(positions, 2)
    geometrical_groups = load_geometrical_groups_data(total_nodes)
    physical_groups = load_physical_groups_data(total_nodes)
    return NodeData(
        total_nodes,
        positions,
        geometrical_groups,
        physical_groups
    )
end


"""Get mesh elements from the mesh imported file"""
function load_elements_data(dimension)
    elements = Vector{ElementsData}()
    # get only elements dimensions
    elements_types, _, nodes_tags = Gmsh.gmsh.model.mesh.getElements(dimension, -1)
    @assert isempty(elements_types) == false "The mesh loader could not find any elements with dimension $dimension for the imported mesh."
    for (element_type, connectivity) in zip(elements_types, nodes_tags)
        element_type_data = parse_element_type_data(element_type)
        elements_connectivity = convert(
            Matrix{Int64}, 
            reshape(connectivity, (element_type_data.nodes_per_element, :))
        )
        push!(
            elements, 
            ElementsData(
                element_type_data,
                size(elements_connectivity, 2),
                elements_connectivity
            )
        )
    end
    return elements
end


"""Get data for the geometrical groups"""
function load_geometrical_groups_data(total_nodes::Int64)
    # keep the mapping for the node group id to its name and
    # keep a list of groups for each node in the mesh
    groups_names = Dict{Int64, String}()
    groups = zeros(Int64, total_nodes)
    return GeometricalGroupsData(groups_names, groups)
end


"""Get data for the physical groups"""
function load_physical_groups_data(total_nodes::Int64)
    # keep the mapping for the node group id to its name and
    # keep a list of groups for each node in the mesh
    groups_names = Dict{Int64, String}()
    groups = zeros(Int64, total_nodes)
    # get all the groups, no matter the dimensions of entity
    for (dimension, physical_tag) in Gmsh.gmsh.model.getPhysicalGroups()
        @assert physical_tag ≥ 0 "All physical groups must be ≥ 0"
        group_name = Gmsh.gmsh.model.getPhysicalName(dimension, physical_tag)
        @assert !(physical_tag in keys(groups_names)) "The names of physical groups $group_name should be unique"
        if physical_tag > 0
            @assert isempty(group_name) == false "All physical group must have a name to identify the domain conditions"
            groups_names[physical_tag] = group_name
            # get all node tags for each entity and set then to the groups numbers vector
            # only if they are greater than the values that was already set for a specific node
            for entity_tag in Gmsh.gmsh.model.getEntitiesForPhysicalGroup(dimension, physical_tag)
                _, _, nodes_tags = Gmsh.gmsh.model.mesh.getElements(dimension, entity_tag)
                nodes_ids = convert(Vector{Int64}, nodes_tags[1])
                # if a group has a value less than physical_tag than update, 
                # otherwise just keep the current group number
                groups[nodes_ids] = map(
                    group -> group < physical_tag ? physical_tag : group, 
                    groups[nodes_ids]
                )
            end
        end
    end
    return PhysicalGroupsData(groups_names, groups)
end