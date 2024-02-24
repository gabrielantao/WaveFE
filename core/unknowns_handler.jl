"""This holds data of all unknowns for a given model"""
mutable struct UnknownsHandler
    # values of unknowns
    values::Dict{String, Vector{Float64}}
    # last time step values of unknowns 
    old_values::Dict{String, Vector{Float64}}
    converged::Dict{String, Bool}
    convergence_tolerance_relative::Dict{String, Float64}
    convergence_tolerance_absolute::Dict{String, Float64}
    # TODO [general performance improvements]
    ## register a variable here with the only variables that must be checked 
end


"""Load data for initial conditions needed to the simulation"""
function load_unknowns_handler(
    all_solved_unknowns, domain_condition_groups, domain_conditions_data
)
    values = Dict{Tuple{String, ConditionType}, Vector{Int64}}()
    old_values = Dict{Tuple{String, ConditionType}, Vector{Float64}}()
    # get boundary conditions
    for condition_data in domain_conditions_data["initial"]
        if condition_data["unknown_name"] in all_solved_unknowns
            group_number = condition_data["group_number"]
            unknown = condition_data["unknown"]
            value = condition_data["value"]
            curent_group_indices = findall(
                domain_condition_group -> domain_condition_group == group_number, 
                domain_condition_groups
            )
            values[curent_group_indices] .= value
            old_values[curent_group_indices] .= value
        end
    end
    return UnknownsHandler(
        values,
        old_values,
        Dict(unknown => false for unknown in all_solved_unknowns),
        simulation_parameters["simulation"]["tolerance_relative"],
        simulation_parameters["simulation"]["tolerance_absolute"]
    )
end

"""Get the values of the unknowns for the nodes"""
function get_values(
    unknowns_handler::UnknownsHandler, 
    unknown::String,
    nodes_ids::Vector{Int64}
)
    return unknowns_handler.values[unknown][nodes_ids]
end


"""Get the old values of the unknowns for the nodes"""
function get_old_values(
    unknowns_handler::UnknownsHandler, 
    unknown::String,
    nodes_ids::Vector{Int64}
)
    return unknowns_handler.old_values[unknown][nodes_ids]
end


"""Update values for old variables"""
function update!(unknowns_handler::UnknownsHandler)
    for unknown in keys(unknowns_handler.values)
        copy!(unknowns_handler.old_values[unknown], unknowns_handler.values[unknown])
    end
end


"""Check values for convergence of unknowns"""
function check_unknowns_convergence!(unknowns_handler::UnknownsHandler)
    for unknown in unknowns_handler.variables
        unknowns_handler.converged[unknown] = all(
            isapprox.(
                unknowns_handler.values[unknown], 
                unknowns_handler.old_values[unknown], 
                rtol=unknowns_handler.convergence_tolerance_relative[unknown], 
                atol=unknowns_handler.convergence_tolerance_absolute[unknown]
            )
        )
    end
end