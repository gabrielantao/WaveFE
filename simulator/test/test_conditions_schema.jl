@testset "condition schema validator" begin 
    @testset "build condition general section" begin
        # check valid entries
        valid_entries = [
            Dict("version" => "1.0", "description" => "some description"),
            Dict("version" => "1.5", "description" => ""),
            Dict("version" => "1.0"),
        ]
        for entry_data in valid_entries
            section = WaveCore.ConditionsFileSchema.build_general_section(entry_data)
            @test section.version == pop!(entry_data, "version")
            @test section.description == pop!(entry_data, "description", "")
            WaveCore.ConditionsFileSchema.validate_schema(section)
        end

        # wrong entries
        invalid_entries = [
            Dict("version" => 9.0),
            Dict("description" => 1.0),
            Dict("not_suported_field" => 9999)
        ]
        valid_entry = Dict("version" => "1.0", "description" => "some description")
        for wrong_data in invalid_entries
            invalid_entry = merge(valid_entry, wrong_data)
            @test_throws AssertionError WaveCore.ConditionsFileSchema.build_general_section(invalid_entry)
        end
    end


    @testset "build condition initial section" begin
        # check valid entries
        valid_entries = [
            Dict(
                "group_name" => "group 1", 
                "unknown" => "a", 
                "value" => 0.0, 
                "description" => "some description"
            ),
            Dict(
                "group_name" => "group 2", 
                "unknown" => "b", 
                "value" => 0.0,
            ),
        ]
        for entry_data in valid_entries
            section = WaveCore.ConditionsFileSchema.build_initial_section(entry_data)
            @test section.group_name == pop!(entry_data, "group_name")
            @test section.unknown == pop!(entry_data, "unknown")
            @test section.value == pop!(entry_data, "value")
            @test section.description == pop!(entry_data, "description", "")
            WaveCore.ConditionsFileSchema.validate_schema(section)
        end

        # wrong entries
        invalid_entries = [
            Dict("group_name" => [90, 10]),
            Dict("unknown" => 0), 
            Dict("value" => "0.0"), 
            Dict("description" => 0),
            Dict("not_suported_field" => 9999)
        ]
        valid_entry = Dict(
            "group_name" => "group 1", 
            "unknown" => "a", 
            "value" => 0.0, 
            "description" => "some description"
        )
        for wrong_data in invalid_entries
            invalid_entry = merge(valid_entry, wrong_data)
            @test_throws AssertionError WaveCore.ConditionsFileSchema.build_initial_section(invalid_entry)
        end
    end


    @testset "build condition boundary section" begin
        # check valid entries
        valid_entries = [
            Dict(
                "group_name" => "group 1", 
                "condition_type" => 1, 
                "unknown" => "a", 
                "value" => 0.0, 
                "description" => "some description"
            ),
            Dict(
                "group_name" => "group 2", 
                "condition_type" => 1, 
                "unknown" => "b", 
                "value" => 0.0,
            ),
        ]
        for entry_data in valid_entries
            section = WaveCore.ConditionsFileSchema.build_boundary_section(entry_data)
            @test section.group_name == pop!(entry_data, "group_name")
            @test section.condition_type == WaveCore.FIRST::ConditionType
            @test section.unknown == pop!(entry_data, "unknown")
            @test section.value == pop!(entry_data, "value")
            @test section.description == pop!(entry_data, "description", "")
            WaveCore.ConditionsFileSchema.validate_schema(section)
        end

        # wrong entries
        invalid_entries = [
            Dict("group_name" => [90, 10]),
            Dict("condition_type" => 1), 
            Dict("unknown" => 0), 
            Dict("value" => "0.0"), 
            Dict("description" => 0),
            Dict("not_suported_field" => 9999)
        ]
        valid_entry = Dict(
            "group_name" => "group 1", 
            "condition_type" => 1, 
            "unknown" => "a", 
            "value" => 0.0, 
            "description" => "some description"
        )
        for wrong_data in invalid_entries
            invalid_entry = merge(valid_entry, wrong_data)
            @test_throws AssertionError WaveCore.ConditionsFileSchema.build_general_section(invalid_entry)
        end
    end  


    @testset "build condition whole schema" begin
        case_folder = joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity") 
        conditions = WaveCore.ConditionsFileSchema.ConditionsData(
            TOML.parsefile(joinpath(case_folder, WaveCore.DOMAIN_CONDITIONS_FILENAME))
        )
        @test isempty(conditions.initial) == false
        @test isempty(conditions.boundary) == false
    end  
end