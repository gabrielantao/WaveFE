@testset "assembler" begin
    function get_unknowns()
        # get the reference data to build a LHS matrix fixture 
        data_filepath = joinpath(
            WAVE_SIMULATOR_TEST_PATH, "data", "case_square_cavity", "results_reference"
        )
        # intermediate velocities loaded here to assemble second step equation
        filepath = joinpath(data_filepath, "t_2_u_1_int.csv")
        u_1 = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_2_u_2_int.csv")
        u_2 = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_2_p.csv")
        p = readdlm(filepath, ',', Float64, '\n')[:, 1]
        # efective velocity of last time step for the old values
        filepath = joinpath(data_filepath, "t_1_u_1_efet.csv")
        u_1_old = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_1_u_2_efet.csv")
        u_2_old = readdlm(filepath, ',', Float64, '\n')[:, 1]
        return WaveCore.UnknownsHandler(
            Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
            Dict("u_1" => u_1_old, "u_2" => u_2_old, "p" => p),
            Dict("u_1" => false, "u_2" => false, "p" => false),
            Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
            Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
        )
    end

    # get the reference data to build a LHS matrix fixture 
    function get_reference_lhs(step)
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "reference.hdf5"), "r")
        # offset 1 position because all indices started at zero (Python generated)
        indices = read(data["/t_0/step $step/lhs_assembled/indices"])
        values = read(data["/t_0/step $step/lhs_assembled/values"])
        # input all the relevant data to build the model 
        return sparse(Vector{Int64}(indices[1, :]), Vector{Int64}(indices[2, :]), values)
    end

    # get the reference data to build a LHS matrix fixture 
    function get_reference_rhs(step)
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "reference.hdf5"), "r")
        # offset 1 position because all indices started at zero (Python generated)
        return read(data["/t_1/step $step/rhs_assembled"])
    end

    mesh = WaveCore.build_mesh(
        case_square_cavity_triangles.mesh_data, 
        case_square_cavity_triangles.simulation_data
    )
    unknowns_handler = get_unknowns()
    model_parameters = ModelSemiImplicitParameters(
        false, 
        case_square_cavity_triangles.simulation_data.simulation.safety_Δt_factor,
        Dict("Re" => case_square_cavity_triangles.simulation_data.parameter.parameters["Re"])
    )
    # update the parameters for the elements 
    WaveCore.update_elements!(mesh, unknowns_handler, model_parameters)


    @testset "assembler indices generator" begin
        @test WaveCore.get_global_indices(2, 2, [1, 53, 52], WaveCore.DIAGONAL::MatrixType) == (53, 53)
        @test WaveCore.get_global_indices(2, 3, [1, 53, 52], WaveCore.DENSE::MatrixType) == (53, 52)
        @test WaveCore.get_global_indices(2, 2, [1, 53, 52], WaveCore.SYMMETRIC::MatrixType) == (53, 53)
        # it should always only return the upper element in the matrix when SYMMETRIC
        @test WaveCore.get_global_indices(2, 3, [1, 53, 52], WaveCore.SYMMETRIC::MatrixType) == (52, 53)
    end

    @testset "diagonal LHS matrix" begin
        equation_one = EquationStepOne(
            ["u_1", "u_2"], case_square_cavity_triangles.simulation_data
        )
        # if mesh must refresh it must update the assembler indices
        WaveCore.update_assembler_indices!(equation_one.base.assembler, mesh)
        assembled_lhs = assemble_global_lhs(
            equation_one, 
            mesh,
            unknowns_handler,
            model_parameters
        )

        indices_i, indices_j, values = findnz(dropzeros(assembled_lhs))
        @test indices_i == indices_j
        @test length(values) == 2601
        # check diagonal values 
        @test check_reference_csv(
            "ref_global_assembling",
            "lhs_diagonal_indices.csv", 
            [[i, j] for (i, j) in zip(indices_i, indices_j)]
        )
        @test check_reference_csv(
            "ref_global_assembling",
            "lhs_diagonal_values.csv", 
            values
        )
    end


    @testset "symmetric LHS matrix" begin
        equation_two = EquationStepTwo(
            ["p"], case_square_cavity_triangles.simulation_data
        )
        # if mesh must refresh it must update the assembler indices
        WaveCore.update_assembler_indices!(equation_two.base.assembler, mesh)
        assembled_lhs = assemble_global_lhs(
            equation_two, 
            mesh,
            unknowns_handler,
            model_parameters
        )
        
        indices_i, indices_j, values = findnz(assembled_lhs)

        # check symmetric
        @test all([assembled_lhs[j, i] ≈ assembled_lhs[i, j] for (i, j) in zip(indices_i, indices_j)])

        # save regression data
        @test check_reference_csv(
            "ref_global_assembling",
            "lhs_symmetric_indices.csv", 
            [[i, j] for (i, j) in zip(indices_i, indices_j)]
        )
        @test check_reference_csv(
            "ref_global_assembling",
            "lhs_symmetric_values.csv", 
            values
        )
    end

    @testset "RHS vector" begin
        equation_one = EquationStepOne(
            ["u_1", "u_2"], case_square_cavity_triangles.simulation_data
        )
        assembled_rhs = assemble_global_rhs(
            equation_one, 
            mesh,
            unknowns_handler,
            model_parameters
        )
        
        @test check_reference_csv(
            "ref_global_assembling",
            "rhs_step_1_u_1.csv", 
            assembled_rhs["u_1"]
        )
        @test check_reference_csv(
            "ref_global_assembling",
            "rhs_step_1_u_2.csv", 
            assembled_rhs["u_2"]
        )
    end

end
