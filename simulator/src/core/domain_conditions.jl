export DomainConditions
export ConditionType


"""
First type condtions specifies the values of variable applied at the boundary (AKA Dirichlet)
Second type condtions specifies the values of the derivative applied at the boundary of the domain. (AKA  Neumann condition)
"""
@enum ConditionType begin
    FIRST = 1
    SECOND = 2
    # TODO [implement other domain conditions]
    ## maybe implement in the future the other conditions (Cauchy and Robin) with combination of these two others
end


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


"""Load data for domain conditions needed to the simulation"""
function load_domain_conditions(input_data, domain_conditions_data)
    indices = Dict{Tuple{String, ConditionType}, Vector{Int64}}()
    values = Dict{Tuple{String, ConditionType}, Vector{Float64}}()
    domain_conditions_groups = read(input_data["mesh/nodes/domain_condition_groups"])
    # preallocate the vectors
    for condition_data in domain_conditions_data["boundary"]
        unknown = condition_data["unknown"]
        condition_type = get_condition_type(condition_data["condition_type"])
        indices[(unknown, condition_type)] = Int64[]
        values[(unknown, condition_type)] = Float64[]
    end
    # get boundary conditions
    for condition_data in domain_conditions_data["boundary"]
        group_number = parse(Int64, condition_data["group_name"])
        unknown = condition_data["unknown"]
        value = condition_data["value"]
        condition_type = get_condition_type(condition_data["condition_type"])
        current_group_indices = findall(
            domain_condition_group -> domain_condition_group == group_number, 
            domain_conditions_groups
        )
        append!(indices[(unknown, condition_type)], current_group_indices)
        append!(values[(unknown, condition_type)], fill(value, length(current_group_indices)))
    end
    return DomainConditions(indices, values)
end


"""Auxiliary function to convert a type number of condition into the enum values"""
function get_condition_type(condition_type_number)
    if condition_type_number == 1
        return FIRST::ConditionType
    elseif condition_type_number == 2
        return SECOND::ConditionType
    else
        throw("Not implement group number of type $condition_type_number")
    end
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
    #logger.info("applying conditions to LHS")
    # output_manager.write_debug(
    #     f"{self.label}/{unknown}/lhs_condition_applied",
    #     self.lhs_condition_applied[unknown],
    # )
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
    #logger.info("applying conditions to RHS")
    # output_manager.write_debug(
    #     f"{self.label}/{unknown}/rhs_condition_applied",
    #     rhs_condition_applied,
    # )
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