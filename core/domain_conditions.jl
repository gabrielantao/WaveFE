"""
First type condtions specifies the values of variable applied at the boundary (AKA Dirichlet)
Second type condtions specifies the values of the derivative applied at the boundary of the domain. (AKA  Neumann condition)
"""
@enum ConditionType begin
    FIRST = 1
    SECOND = 2
    # TODO: maybe implement in the future the other conditions (Cauchy and Robin) with combination of these two others
end


"""
This struct holds data related to domain conditions
NOTE: initial conditions is already applied by the fronted code i.e. the initial values
are imported in the simulation
"""
struct DomainConditions
    # indices and values of nodes that have domain conditions values
    # the keys are the unknown name and condition type
    indices::Dict{Tuple{String, ConditionType}, Vector{Int32}}
    values::Dict{Tuple{String, ConditionType}, Vector{Float64}}
end


"""Load data for domain conditions needed to the simulation"""
function load_domain_conditions(input_data)
    indices = Dict{Tuple{String, ConditionType}, Vector{Int32}}()
    values = Dict{Tuple{String, ConditionType}, Vector{Float64}}()
    for unknown in keys(input_data["domain_conditions"]["first_type"])
        indices[(unknown, FIRST::ConditionType)] = input_data["domain_conditions"]["first_type"][unknown]["indices"]
        values[(unknown, FIRST::ConditionType)] = input_data["domain_conditions"]["first_type"][unknown]["values"]
    end
    # TODO: Load second type conditions here
    return DomainConditions(
        indices,
        values
    )
end


"""Apply boundary conditions to the LHS matrix"""
function apply_domain_conditions_lhs!(
    domain_conditions::DomainConditions, 
    unknown::String,
    lhs::SparseMatrixCSC{Float64, Int32},
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
    # TODO: check how to apply condition for the other type here
end


"""Apply boundary conditions to the RHS vector"""
function apply_domain_conditions_rhs!(
    domain_conditions::DomainConditions, 
    unknown::String,
    assembled_lhs::SparseMatrixCSC{Float64, Int32},
    rhs::Vector{Float64},
)
    #logger.info("applying conditions to RHS")
    # output_manager.write_debug(
    #     f"{self.label}/{unknown}/rhs_condition_applied",
    #     rhs_condition_applied,
    # )
    # first condition application
    indices = domain_conditions.indices[
        (unknown, ConditionType.FIRST.value)
    ]
    values = domain_conditions.values[
        (unknown, ConditionType.FIRST.value)
    ]
    offset_vector = calculate_rhs_offset_values(
        assembled_lhs, indices, values
    )
    rhs = rhs - offset_vector
    rhs[indices] .= values
    # TODO: do the calculations for the other condition_types
end


"""
Calculate the vector to be added to rhs vector due domain condition application.
To zero a column of the LHS matrix the column values must be multiplied by the known
value and added to the RHS vector to give a right offset.
"""
function calculate_rhs_offset_values(
    assembled_lhs::SparseMatrixCSC{Float64, Int32},
    indices::Vector{Int32},
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