abstract type ValidatorSchema end
abstract type ValidatorSection end


const VERSION_FIELD_NAME_PATTERN = r"^[0-9]+\.[0-9]+$"
const UNKNOWN_FIELD_NAME_PATTERN = r"^[a-zA-Z]\w*$"
const CASE_ALIAS_FIELD_NAME_PATTERN = r"^\w+$"

export ValidatorSchema, ValidatorSection
export get_section_field, assert_only_supported_entries
export field_match_pattern, field_less_than, field_greater_than
export VERSION_FIELD_NAME_PATTERN, UNKNOWN_FIELD_NAME_PATTERN, CASE_ALIAS_FIELD_NAME_PATTERN


function get_section_field(data, field_name, expected_type, default=nothing)
    field = pop!(data, field_name, default)
    @assert field isa expected_type "The field $field_name should be of type $expected_type but it is $(typeof(field))"
    return field
end


function field_match_pattern(field_name, field_value, pattern)
    error_message = "Field $field_name = $field_value should match pattern $pattern"
    @assert occursin(pattern, field_value) error_message
end


function field_less_than(field_name, field_value, upper_limit, include_limit=true)
    error_message = "Field $field_name = $field_value should be $(include_limit ? "≤" : "<") $upper_limit"
    @assert (include_limit ? field_value ≤ upper_limit : field_value < upper_limit) error_message
end


function field_greater_than(field_name, field_value, lower_limit, include_limit=true)
    error_message = "Field $field_name = $field_value should be $(include_limit ? "≥" : ">") $lower_limit"
    @assert (include_limit ? field_value ≥ lower_limit : field_value > lower_limit) error_message
end


function assert_only_supported_entries(data, section_name)
    invalid_entries = join(collect(keys(data)), ", ")
    @assert isempty(data) "There are not supported inputs in the section $section_name:\n$invalid_entries"
end