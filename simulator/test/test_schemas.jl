@testset "check validators" begin
    # the function that get the fields from data section
    data = Dict("version" => "1.0", "value" => [3.0, 2.0])
    @test WaveCore.get_section_field(copy(data), "version", String) == "1.0"
    @test WaveCore.get_section_field(copy(data), "description", String, "default description") == "default description"
    @test_throws AssertionError WaveCore.get_section_field(copy(data), "value", Float64)
    @test_throws AssertionError WaveCore.get_section_field(copy(data), "description", String)
        
    # the field matcher pattern
    WaveCore.field_match_pattern(
        "version",
        "1.2",
        WaveCore.VERSION_FIELD_NAME_PATTERN
    )
    @test_throws AssertionError WaveCore.field_match_pattern(
        "version",
        "1.2.3.4", 
        WaveCore.VERSION_FIELD_NAME_PATTERN
    )
        
    # check values inside limits
    WaveCore.field_less_than("value", 0.0, 1.0)
    WaveCore.field_less_than("value", 1.0, 1.0)
    @test_throws AssertionError WaveCore.field_less_than("value", 1.0, 1.0, false)
    WaveCore.field_greater_than("value", 2.0, 1.0)
    WaveCore.field_greater_than("value", 1.0, 1.0)
    @test_throws AssertionError WaveCore.field_greater_than("value", 1.0, 1.0, false)

    # the function that checks that all fields were collected
    WaveCore.assert_only_supported_entries(Dict(), "section_name")
    @test_throws AssertionError WaveCore.assert_only_supported_entries(
        data, "section_name"
    )
end