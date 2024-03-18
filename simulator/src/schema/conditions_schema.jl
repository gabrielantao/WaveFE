module ConditionsFileSchema
using ..WaveCore

export DomainConditionsData, load_domain_conditions_data

struct GeneralSection <: DataSection
    version::String
    description::String
end


function build_general_section(section_data)
    data = copy(section_data)
    version = get_section_field(data, "version", String)
    description = get_section_field(data, "description", String, "")
    assert_only_supported_entries(data, "general")
    return GeneralSection(
        version,
        description
    )
end


function validate_schema(section::GeneralSection)
    field_match_pattern(
        "version",
        section.version, 
        VERSION_FIELD_NAME_PATTERN, 
    )
end


struct InitialSection <: DataSection
    group_name::String
    unknown::String
    value::Float64
    description::String
end


function build_initial_section(section_data)
    data = copy(section_data)
    group_name = get_section_field(data, "group_name", String)
    unknown = get_section_field(data, "unknown", String)
    value = get_section_field(data, "value", Float64)
    description = get_section_field(data, "description", String, "")
    assert_only_supported_entries(data, "initial")
    return InitialSection(
        group_name,
        unknown,
        value,
        description
    )
end


function validate_schema(section::InitialSection)
    field_match_pattern(
        "unknown",
        section.unknown,
        UNKNOWN_FIELD_NAME_PATTERN
    )
end


struct BoundarySection <: DataSection
    group_name::String
    condition_type::ConditionType
    unknown::String
    value::Float64
    description::String
end


function build_boundary_section(section_data)
    data = copy(section_data)
    group_name = get_section_field(data, "group_name", String)
    condition_type = WaveCore.get_condition_type(
        get_section_field(
            data,
            "condition_type",
            Int64
        )
    )
    unknown = get_section_field(data, "unknown", String)
    value = get_section_field(data, "value", Float64)
    description = get_section_field(data, "description", String, "")
    assert_only_supported_entries(data, "boundary")
    return BoundarySection(
        group_name,
        condition_type,
        unknown,
        value,
        description
    )
end


function validate_schema(section::BoundarySection)
    field_match_pattern(
        "unknown",
        section.unknown, 
        UNKNOWN_FIELD_NAME_PATTERN
    )
end


struct DomainConditionsData <: DataSchema
    general::GeneralSection
    initial::Vector{InitialSection}
    boundary::Vector{BoundarySection}    
end


function load_domain_conditions_data(folder::String) 
    data = WaveCore.TOML.parsefile(folder)
    return DomainConditionsData(
        build_general_section(data["general"]),
        [build_initial_section(section) for section in data["initial"]],
        [build_boundary_section(section) for section in data["boundary"]]
    )
end


function validate_schema(schema::DomainConditionsData)
    @assert isempty(schema.initial) == false, "The initial conditions could not be empty"
    @assert isempty(schema.boundary) == false, "The boundary conditions could not be empty"
    validate_schema(schema.general)
    validate_schema(schema.initial)
    validate_schema(schema.boundary)
end

end # module