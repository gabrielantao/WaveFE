module SimulationFileSchema
using ..WaveCore

export SimulationData, load_simulation_data

struct GeneralSection <: DataSection
    version::String
    title::String
    description::String
    alias::String
end


function build_general_section(section_data)
    data = copy(section_data)
    version = get_section_field(data, "version", String)
    title = get_section_field(data, "title", String, "")
    description = get_section_field(data, "description", String, "")
    alias = get_section_field(data, "alias", String)
    assert_only_supported_entries(data, "general")
    return GeneralSection(
        version,
        title,
        description,
        alias
    )
end


function validate_schema(section::GeneralSection)
    field_match_pattern(
        "version",
        section.version,
        VERSION_FIELD_NAME_PATTERN, 
    )
    field_match_pattern(
        "alias",
        section.alias, 
        CASE_ALIAS_FIELD_NAME_PATTERN
    )
    @assert length(section.alias) ≤ WaveCore.MAXIMUM_LENGTH_ALIAS "The length of the alias must be smaller than 40 characteres."
end


struct SimulationSection <: DataSection
    model::String
    steps_limit::Int64
    transient::Bool
    safety_Δt_factor::Float64
    mesh::String
    tolerance_relative::Dict{String, Float64}
    tolerance_absolute::Dict{String, Float64}
end


function build_simulation_section(section_data)
    data = copy(section_data)
    model = get_section_field(data, "model", String)
    steps_limit = get_section_field(data, "steps_limit", Int64)
    transient = get_section_field(data, "transient", Bool)
    safety_Δt_factor = get_section_field(data, "safety_dt_factor", Float64)
    mesh = get_section_field(data, "mesh", String)
    raw_tolerance_relative = pop!(data, "tolerance_relative", Dict{String, Float64}())
    raw_tolerance_absolute = pop!(data, "tolerance_absolute", Dict{String, Float64}())
    @assert isempty(raw_tolerance_relative) == false "tolerance_relative could not be empty"
    @assert isempty(raw_tolerance_absolute) == false "tolerance_absolute could not be empty"
    
    tolerance_relative = Dict{String, Float64}(
        field_name => get_section_field(raw_tolerance_relative, field_name, Float64) for field_name in keys(raw_tolerance_relative)
    )
    tolerance_absolute = Dict{String, Float64}(
        field_name => get_section_field(raw_tolerance_absolute, field_name, Float64) for field_name in keys(raw_tolerance_absolute)
    )
    assert_only_supported_entries(data, "simulation")
    return SimulationSection(
        model,
        steps_limit,
        transient,
        safety_Δt_factor,
        mesh,
        tolerance_relative,
        tolerance_absolute
    )
end


function validate_schema(section::SimulationSection)
    field_greater_than("steps_limit", section.steps_limit, 0, false)
    field_greater_than("safety_dt_factor", section.safety_Δt_factor, 0.0, false)
    field_less_than("safety_dt_factor", section.safety_Δt_factor, 1.0)
    for (field_name, field_value) in section.tolerance_relative
        field_greater_than("tolerance_relative/$field_name", field_value, 0.0, false)
        field_less_than("tolerance_relative/$field_name", field_value, 1.0)
    end
    for (field_name, field_value) in section.tolerance_absolute
        field_greater_than("tolerance_absolute/$field_name", field_value, 0.0)
    end
end


struct ParameterSection <: DataSection
    parameters::Dict{String, Float64}
end


function build_parameter_section(section_data)
    if isnothing(section_data)
        return ParameterSection(Dict{String, Float64}())
    end 
    data = copy(section_data)
    parameters = Dict(
        field_name => get_section_field(data, field_name, Float64) for (field_name, _) in data
    )
    assert_only_supported_entries(data, "parameter")
    return ParameterSection(parameters)
end


function validate_schema(section::ParameterSection)
    for field_name in keys(section.parameters)
        field_match_pattern(
            "parameters",
            field_name, 
            UNKNOWN_FIELD_NAME_PATTERN
        )
    end
end


struct SolverSection <: DataSection
    type::SolverType
    preconditioner_type::PreconditionerType
    steps_limit::Int64
    tolerance_relative::Float64
    tolerance_absolute::Float64
end


function build_solver_section(section_data)
    data = copy(section_data)
    type = WaveCore.get_solver_type(
        get_section_field(data, "type", String)
    )
    preconditioner_type = WaveCore.get_solver_preconditioner_type(
        get_section_field(data, "preconditioner", String)
    )
    steps_limit = get_section_field(data, "steps_limit", Int64)
    tolerance_relative = get_section_field(data, "tolerance_relative", Float64)
    tolerance_absolute = get_section_field(data, "tolerance_absolute", Float64)
    assert_only_supported_entries(data, "solver")
    return SolverSection(
        type, preconditioner_type, steps_limit, tolerance_relative, tolerance_absolute
    )
end


function validate_schema(section::SolverSection)
    field_greater_than("steps_limit", section.steps_limit, 0, false)
    field_greater_than("tolerance_relative", section.tolerance_relative, 0.0, false)
    field_less_than("tolerance_relative", section.tolerance_relative, 1.0)
    field_greater_than("tolerance_absolute", section.tolerance_absolute, 0.0)
end



struct OutputSection <: DataSection
    frequency::Int64
    save_result::Bool
    save_numeric::Bool
    save_mesh::Bool
    save_debug::Bool
    unknowns::Vector{String}
end


function build_output_section(section_data)
    data = copy(section_data)
    frequency = get_section_field(data, "frequency", Int64)
    save_result = get_section_field(data, "save_result", Bool)
    save_numeric = get_section_field(data, "save_numeric", Bool)
    save_mesh = get_section_field(data, "save_mesh", Bool)
    save_debug = get_section_field(data, "save_debug", Bool)
    unknowns = get_section_field(data, "unknowns", Vector{String})
    assert_only_supported_entries(data, "output")
    return OutputSection(
        frequency, save_result, save_numeric, save_mesh, save_debug, unknowns
    )
end


function validate_schema(section::OutputSection)
    field_greater_than("frequency", section.frequency, 0, false)
    for unknown in section.unknowns
        field_match_pattern(
            "unknowns",
            unknown, 
            UNKNOWN_FIELD_NAME_PATTERN
        )
    end
end


struct SimulationData <: DataSchema
    general::GeneralSection
    simulation::SimulationSection
    parameter::ParameterSection
    solver::SolverSection
    output::OutputSection
end


function load_simulation_data(folder::String) 
    data = WaveCore.TOML.parsefile(folder)
    return SimulationData(
        build_general_section(data["general"]),
        build_simulation_section(data["simulation"]),
        build_parameter_section(data["parameter"]),
        build_solver_section(data["solver"]),
        build_output_section(data["output"]),
    )
end


function validate_schema(schema::SimulationData)
    validate_schema(schema.general)
    validate_schema(schema.simulation)
    validate_schema(schema.parameter)
    validate_schema(schema.solver)
    validate_schema(schema.output)
end


end # module