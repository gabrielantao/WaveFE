"""This holds data of all unknowns for a given model"""
mutable struct UnknownsHandler
    # values of unknowns
    values::Dict{String, Vector{Float64}}
    # last time step values of unknowns 
    old_values::Dict{String, Vector{Float64}}
    converged::Dict{String, Bool}
    convergence_tolerance_relative::Dict{String, Float64}
    convergence_tolerance_absolute::Dict{String, Float64}
    # TODO: register a variable here with the only variables that must be checked 
end


"""Load data for the unkonwns handler from the input files"""
function load_unkowns_handler(input_data, simulation_parameters)
    # TODO: check if is represented as vectors here 
    values = input_data["unknowns"]
    # TODO: check here if it should update this 
    old_values = input_data["unknowns"]
    return UnknownsHandler(
        values,
        old_values,
        Dict{String, Bool}(),
        simulation_parameters["simulation"]["tolerance_relative"],
        simulation_parameters["simulation"]["tolerance_absolute"]
    )
end


"""Update values for old variables"""
function refresh_values(unknowns_handler::UnknownsHandler)
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