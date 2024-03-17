export DomainConditions

"""
This struct holds data related to domain conditions
NOTE: initial conditions is already applied by the fronted code i.e. the initial values
are imported in the simulation
"""
struct DomainConditions
    # indices and values of nodes that have domain conditions values
    # the keys are the unknown name and condition type
    indices::Dict{Tuple{String, ConditionType}, Vector{Int64}}
    values::Dict{Tuple{String, ConditionType}, Vector{Float64}}
end


# TODO: check the type received for the mesh
"""Load data for domain conditions needed to the simulation"""
function build_domain_conditions(
    mesh_data::MeshData, domain_conditions_data::DomainConditionsData
)
    indices = Dict{Tuple{String, ConditionType}, Vector{Int64}}()
    values = Dict{Tuple{String, ConditionType}, Vector{Float64}}()
    domain_conditions_groups = mesh_data.nodes.physical_groups.groups
    # preallocate the vectors
    for condition_data in domain_conditions_data.boundary
        unknown = condition_data.unknown
        condition_type = condition_data.condition_type
        indices[(unknown, condition_type)] = Int64[]
        values[(unknown, condition_type)] = Float64[]
    end
    # get boundary conditions
    for condition_data in domain_conditions_data.boundary
        group_number = parse(Int64, condition_data.group_name)
        unknown = condition_data.unknown
        value = condition_data.value
        condition_type = condition_data.condition_type
        current_group_indices = findall(
            domain_condition_group -> domain_condition_group == group_number, 
            domain_conditions_groups
        )
        append!(indices[(unknown, condition_type)], current_group_indices)
        append!(values[(unknown, condition_type)], fill(value, length(current_group_indices)))
    end
    return DomainConditions(indices, values)
end


"""Setup initial boundary values for the unknowns"""
function setup_boundary_values!(
    domain_conditions::DomainConditions,
    unknowns_handler::UnknownsHandler,
)
    for unknown in keys(unknowns_handler.values)
        if haskey(domain_conditions.values, (unknown, FIRST::ConditionType))
            indices = domain_conditions.indices[(unknown, FIRST::ConditionType)]
            values = domain_conditions.values[(unknown, FIRST::ConditionType)]
            unknowns_handler.values[unknown][indices] = values
            unknowns_handler.old_values[unknown][indices] = values
        end
    end
end


"""Apply boundary conditions to the LHS matrix"""
function apply_domain_conditions_lhs!(
    domain_conditions::DomainConditions, 
    unknown::String,
    lhs::SparseMatrixCSC{Float64, Int64},
)
    for index in domain_conditions.indices[(unknown, FIRST::ConditionType)]
        lhs[:, index] .= 0.0
        lhs[index, :] .= 0.0
        lhs[index, index] = 1.0
    end
    # TODO [implement other domain conditions]
    ## do the calculations for the other condition_types
end


"""Apply boundary conditions to the RHS vector"""
function apply_domain_conditions_rhs(
    domain_conditions::DomainConditions, 
    unknown::String,
    assembled_lhs::SparseMatrixCSC{Float64, Int64},
    rhs::Vector{Float64},
)
    # first condition application
    indices = domain_conditions.indices[(unknown, FIRST::ConditionType)]
    values = domain_conditions.values[(unknown, FIRST::ConditionType)]
    offset_vector = calculate_rhs_offset_values(
        assembled_lhs, indices, values
    )
    rhs -= offset_vector
    # force reapply the domain condition for the nodes with these indices
    rhs[indices] = values
    
    # TODO [implement other domain conditions]
    ## do the calculations for the other condition_types
    return rhs
end


"""
Calculate the vector to be added to rhs vector due domain condition application.
To zero a column of the LHS matrix the column values must be multiplied by the known
value and added to the RHS vector to give a right offset.
"""
function calculate_rhs_offset_values(
    assembled_lhs::SparseMatrixCSC{Float64, Int64},
    indices::Vector{Int64},
    values::Vector{Float64}
)
    # offset vector must be same size of the amount of LHS rows
    offset = zeros(assembled_lhs.m)
    # accumulate column vectors in sparse matrix with boundary indices
    for (column_id, value) in zip(indices, values)
        offset += collect(assembled_lhs[:, column_id] * value)
    end
    # ensure zeros in offset vector in positions where boundary are applied
    offset[indices] .= 0.0
    return offset
end