@testset "simulation schema validator" begin
    @testset "build simulation general section" begin
        valid_entries = [
            Dict(
                "version" => "1.0", 
                "title" => "case title", 
                "description" => "some description",
                "alias" => "my_case",
            ),
            Dict(
                "version" => "1.5", 
                "description" => "",
                "alias" => "my_case",
            )
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_general_section(entry_data)
            @test section.version == pop!(entry_data, "version")
            @test section.title == pop!(entry_data, "title", "")
            @test section.description == pop!(entry_data, "description", "")
            @test section.alias == pop!(entry_data, "alias")
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end


    @testset "build simulation section" begin
        valid_entries = [
            Dict(
                "model" => "group 1", 
                "steps_limit" => 1000, 
                "transient" => false, 
                "safety_dt_factor" => 0.5,
                "tolerance_relative" => Dict{String, Float64}("u_1" => 1.0e-2, "p" => 2.0e-2),
                "tolerance_absolute" => Dict{String, Float64}("u_1" => 0.0, "p" => 3.0)
            )
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_simulation_section(entry_data)
            @test section.model == pop!(entry_data, "model")
            @test section.steps_limit == pop!(entry_data, "steps_limit")
            @test section.transient == pop!(entry_data, "transient")
            @test section.safety_Δt_factor == pop!(entry_data, "safety_dt_factor")
            @test section.tolerance_relative == Dict{String, Float64}("u_1" => 1.0e-2, "p" => 2.0e-2)
            @test section.tolerance_absolute == Dict{String, Float64}("u_1" => 0.0, "p" => 3.0)
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end


    @testset "build mesh section" begin
        valid_entries = [
            Dict(
                "filename" => "my_mesh.msh", 
                "interpolation_order" => 1
            )
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_mesh_section(entry_data)
            @test section.filename == pop!(entry_data, "filename")
            @test section.interpolation_order == WaveCore.ORDER_ONE::InterpolationOrder
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end


    @testset "build parameter section" begin
        valid_entries = [
            Dict{String, Float64}("Re" => 1.0, "Ra" => 2.0),
            nothing
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_parameter_section(entry_data)
            @test section.parameters == entry_data || section.parameters == Dict{String, Float64}()
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end


    @testset "build solver section" begin
        valid_entries = [
            Dict(
                "type" => "Conjugate Gradient", 
                "preconditioner" => "Jacobi",
                "steps_limit" => 2000,
                "tolerance_relative" => 1e-5,
                "tolerance_absolute" => 0.0
            )
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_solver_section(entry_data)
            @test section.type == WaveCore.CONJUGATE_GRADIENT::SolverType
            @test section.preconditioner == WaveCore.JACOBI::SolverPreconditioners
            @test section.steps_limit == pop!(entry_data, "steps_limit")
            @test section.tolerance_relative == pop!(entry_data, "tolerance_relative")
            @test section.tolerance_absolute == pop!(entry_data, "tolerance_absolute")
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end


    @testset "build output section" begin
        valid_entries = [
            Dict(
                "frequency" => 100, 
                "save_result" => true,
                "save_numeric" => false,
                "save_debug" => false,
                "unknowns" => ["u_1", "p"]
            )
        ]
        for entry_data in valid_entries
            section = WaveCore.SimulationFileSchema.build_output_section(entry_data)
            @test section.frequency == pop!(entry_data, "frequency")
            @test section.save_result == pop!(entry_data, "save_result")
            @test section.save_numeric == pop!(entry_data, "save_numeric")
            @test section.save_debug == pop!(entry_data, "save_debug")
            @test section.unknowns == pop!(entry_data, "unknowns")
            WaveCore.SimulationFileSchema.validate_schema(section)
        end
    end
end