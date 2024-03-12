abstract type ValidatorSchema end
abstract type ValidatorSection end


const VERSION_FIELD_NAME_PATTERN = r"^[0-9]+\.[0-9]+$"
const UNKNOWN_FIELD_NAME_PATTERN = r"^[a-zA-Z]\w*$"


function get_section_field(data, field_name, expected_type, default=nothing)
    field = pop!(data, field_name, default)
    @assert field isa expected_type "The field $field_name should be of type $expected_type but it is $(typeof(field))"
    return field
end


function assert_only_supported_entries(data, section_name)
    invalid_entries = join(collect(keys(data)), ", ")
    @assert isempty(data) "There are not supported inputs in the section $section_name:\n$invalid_entries"
end


function field_match_pattern(pattern, field, field_name)
    error_message = "Field $field_name should match pattern $pattern"
    @assert occursin(pattern, field) error_message
end


# listed schemas
include("conditions_schema.jl")
include("simulation_schema.jl")