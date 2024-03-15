@testset "domain conditions" begin
    domain_conditions = WaveCore.build_domain_conditions(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.domain_conditions_data
    )
    total_nodes = length(
        read(input_square_cavity_triangles.hdf_data["mesh/nodes/domain_condition_groups"])
    )
    unknowns_handler = UnknownsHandler(
        Dict("u_1" => zeros(total_nodes), "u_2" => zeros(total_nodes), "p" => fill(0.0001, total_nodes)),
        Dict("u_1" => zeros(total_nodes), "u_2" => zeros(total_nodes), "p" => fill(0.0001, total_nodes)),
        Dict("u_1" => false, "u_2" => false, "p" => false),
        Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
        Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
    )

    function get_reference_lhs()
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "reference.hdf5"), "r")
        # offset 1 position because all indices started at zero (Python generated)
        indices = read(data["/t_0/step 2/lhs_assembled/indices"])
        values = read(data["/t_0/step 2/lhs_assembled/values"])
        # input all the relevant data to build the model 
        return sparse(Vector{Int64}(indices[1, :]), Vector{Int64}(indices[2, :]), values)
    end

    @testset "import conditions data" begin
        # TODO [implement other domain conditions]
        ## it only check the first condition here, it should check all conditions
        for unknown in ["u_1", "u_2"]
            indices = domain_conditions.indices[(unknown, WaveCore.FIRST::ConditionType)]
            values = domain_conditions.values[(unknown, WaveCore.FIRST::ConditionType)]
            @test length(indices) == length(values)
            @test check_reference_csv(
                "ref_domain_conditions",
                "indices_$unknown.csv", 
                indices
            )
            @test check_reference_csv(
                "ref_domain_conditions",
                "values_$unknown.csv", 
                values
            )
        end
        @test domain_conditions.indices[("p", WaveCore.FIRST::ConditionType)] == [1]
        @test domain_conditions.values[("p", WaveCore.FIRST::ConditionType)] ≈ [0.0]
    end


    @testset "setup boundary conditions" begin
        # test if it can set initial boundary condition in the variables
        WaveCore.setup_boundary_values!(
            domain_conditions,
            unknowns_handler
        )
        for unknown in ["u_1", "u_2", "p"]
            @test check_reference_csv(
                "ref_domain_conditions",
                "setup_boundary_$unknown.csv", 
                unknowns_handler.values[unknown]
            )
        end
    end


    @testset "apply LHS conditions" begin
        # test if it can apply the LHS conditions
        lhs_step2 = get_reference_lhs()
        WaveCore.apply_domain_conditions_lhs!(
            domain_conditions,
            "u_1",
            lhs_step2
        )
        indices = domain_conditions.indices[("u_1", WaveCore.FIRST::ConditionType)]
        # test diagonal elements and below and above diagonal elements
        @test all([lhs_step2[i, i] ≈ 1.0 for i in indices])
        @test all([all(collect(lhs_step2[i+1:end, i]) .≈ 0.0) for i in indices])
        @test all([all(collect(lhs_step2[1:i-1, i]) .≈ 0.0) for i in indices])
        # regression of lhs with condition applied
        indices_i, indices_j, values = findnz(lhs_step2)
        @test check_reference_csv(
            "ref_domain_conditions",
            "apply_lhs_u_1_indices.csv", 
            [[i, j] for (i, j) in zip(indices_i, indices_j)]
        )
        @test check_reference_csv(
            "ref_domain_conditions",
            "apply_lhs_u_1_values.csv", 
            collect(values)
        )
    end

    @testset "setup RHS conditions" begin
        lhs_step2 = get_reference_lhs()
        indices = domain_conditions.indices[("u_1", WaveCore.FIRST::ConditionType)]
        values = domain_conditions.values[("u_1", WaveCore.FIRST::ConditionType)]
        offset = WaveCore.calculate_rhs_offset_values(lhs_step2, indices, values)
        rhs = zeros(length(offset))
        rhs = WaveCore.apply_domain_conditions_rhs(
            domain_conditions,
            "u_1",
            lhs_step2,
            rhs
        )
        # check if offset vector doens't change anything in the rhs
        @test offset[indices] ≈ zeros(length(indices))
        # check if values at indices are the same defined in first type condition
        @test rhs[indices] ≈ values
        @test check_reference_csv(
            "ref_domain_conditions",
            "apply_rhs_u_1.csv", 
            rhs
        )
    end
end