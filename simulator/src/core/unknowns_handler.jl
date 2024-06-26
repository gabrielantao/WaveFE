export UnknownsHandler

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
function build_unknowns_handler(
    unknowns_default_values::Dict{String, Float64}, 
    mesh_data::MeshData,
    simulation_data::SimulationData,
    domain_conditions_data::DomainConditionsData
)
    # check duplicated conditions 
    unique_boundary_conditions = Set()
    for condition_data in domain_conditions_data.initial
        duplicated_condition_group_error = "The initial condition for group '$(condition_data.group_name)' and unknown $(condition_data.unknown) was defined twice; eliminate the ambiguity."
        condition_tuple = (condition_data.group_name, condition_data.unknown)
        @assert !(condition_tuple in unique_boundary_conditions) duplicated_condition_group_error
        push!(unique_boundary_conditions, condition_tuple)
    end

    # preallocate with de default values chosen by the models
    values = Dict(unknown => fill(value, mesh_data.nodes.total_nodes) for (unknown, value) in unknowns_default_values)
    old_values = Dict(unknown => fill(value, mesh_data.nodes.total_nodes) for (unknown, value) in unknowns_default_values)
    
    # set initial conditions
    all_solved_unknowns = collect(keys(unknowns_default_values))
    for condition_data in domain_conditions_data.initial
        condition_group_error = "The initial condition for group '$(condition_data.group_name)' is not defined in mesh file."
        @assert (condition_data.group_name in keys(mesh_data.nodes.physical_groups.names)) condition_group_error
        if condition_data.unknown in all_solved_unknowns
            group_number = mesh_data.nodes.physical_groups.names[condition_data.group_name]
            unknown = condition_data.unknown
            value = condition_data.value
            current_group_indices = findall(
                domain_condition_group -> domain_condition_group == group_number, 
                mesh_data.nodes.physical_groups.groups
            )
            values[unknown][current_group_indices] .= value
            old_values[unknown][current_group_indices] .= value
        #else
            # TODO [implement validations and input versioning]
            ## log message this variable is not present in the model, ignored
            ## this should be done by the validator (??)
            ## do the same for the tolerance (set default values if tolerances are not in the file)
        end
    end
    return UnknownsHandler(
        values,
        old_values,
        Dict(unknown => false for unknown in all_solved_unknowns),
        simulation_data.simulation.tolerance_relative,
        simulation_data.simulation.tolerance_absolute
    )
end


"""Get unknonws labels"""
function get_registered_unknowns(unknowns_handler::UnknownsHandler)
    return collect(keys(unknowns_handler.values))
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
    for unknown in get_registered_unknowns(unknowns_handler)
        # must ensure all values are finite values
        @assert all(isfinite, unknowns_handler.values[unknown]) "The $unknown has diverged to infinity! 😖 You must debug the case to check what is wrong."
        unknowns_handler.converged[unknown] = all(
            isapprox(
                unknowns_handler.values[unknown], 
                unknowns_handler.old_values[unknown], 
                rtol=unknowns_handler.convergence_tolerance_relative[unknown], 
                atol=unknowns_handler.convergence_tolerance_absolute[unknown]
            )
        )
    end
end