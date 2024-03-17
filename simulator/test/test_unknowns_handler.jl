@testset "unknowns handler data" begin
    unknowns_handler = WaveCore.load_unknowns_handler(
        Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0001),
        case_square_cavity_triangles.mesh_data, 
        case_square_cavity_triangles.simulation_data,
        case_square_cavity_triangles.domain_conditions_data
    )

    @testset "import unknowns data" begin
        for unknown in keys(unknowns_handler.values)
            @test check_reference_csv(
                "ref_initial_conditions",
                "values_$unknown.csv", 
                unknowns_handler.values[unknown]
            )
            @test check_reference_csv(
                "ref_initial_conditions",
                "old_values_$unknown.csv", 
                unknowns_handler.old_values[unknown]
            )

            @test unknowns_handler.converged[unknown] == false
            @test unknowns_handler.convergence_tolerance_relative[unknown] ≈ 8e-5
            @test unknowns_handler.convergence_tolerance_absolute[unknown] ≈ 0.0
        end
    end

    @testset "get unknowns properties" begin
        @test sort(WaveCore.get_registered_unknowns(unknowns_handler)) == sort(["u_1", "u_2", "p"])
        @test WaveCore.get_values(unknowns_handler, "u_1", [1, 53, 52]) ≈ zeros(3)
        @test WaveCore.get_old_values(unknowns_handler, "u_1", [1, 53, 52]) ≈ zeros(3)
    end

    @testset "update unknowns" begin
        unknowns_handler.values["u_1"][1] = 100.0
        new_value = WaveCore.get_values(unknowns_handler, "u_1", [1])[1]
        old_value = WaveCore.get_old_values(unknowns_handler, "u_1", [1])[1]
        @test new_value != old_value
        WaveCore.update!(unknowns_handler)
        new_value = WaveCore.get_values(unknowns_handler, "u_1", [1])[1]
        old_value = WaveCore.get_old_values(unknowns_handler, "u_1", [1])[1]
        @test new_value == old_value
    end

    @testset "convergence of unknowns" begin
        unknowns_handler.values["u_1"] = fill(100.0, length(unknowns_handler.values["u_1"]))
        WaveCore.check_unknowns_convergence!(unknowns_handler)
        @test unknowns_handler.converged["u_1"] == false
        @test unknowns_handler.converged["u_2"] == true
    end
end