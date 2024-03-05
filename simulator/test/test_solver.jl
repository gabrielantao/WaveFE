@testset "solver" begin
    solver = WaveCore.load_solver(input_square_cavity_triangles.simulation_data)

    function get_unknowns(timestep)
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "result.hdf5"), "r")
        u_1 = read(data["/result/t_$timestep/u_1"])
        u_2 = read(data["/result/t_$timestep/u_2"])
        p = read(data["/result/t_$timestep/p"])
        return UnknownsHandler(
            Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
            Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
            Dict("u_1" => false, "u_2" => false, "p" => false),
            Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
            Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
        )
    end

    # get the reference data to build a LHS matrix fixture 
    function get_reference_lhs(step, unknown)
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "reference.hdf5"), "r")
        # offset 1 position because all indices started at zero (Python generated)
        indices = read(data["/t_0/step $step/$unknown/lhs_condition_applied/indices"])
        values = read(data["/t_0/step $step/$unknown/lhs_condition_applied/values"])
        # input all the relevant data to build the model 
        return sparse(Vector{Int64}(indices[1, :]), Vector{Int64}(indices[2, :]), values)
    end

    # get the reference data to build a LHS matrix fixture 
    function get_reference_rhs(step, unknown)
        # get the reference data to build a LHS matrix fixture 
        data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "reference.hdf5"), "r")
        # offset 1 position because all indices started at zero (Python generated)
        return read(data["/t_0/step $step/$unknown/rhs_condition_applied"])
    end

    @testset "import solver data" begin
        @test solver.type == WaveCore.CONJUGATE_GRADIENT::SolverType
        @test solver.preconditioner_type == WaveCore.JACOBI::SolverPreconditioners
        @test solver.steps_limit == 10000
        @test solver.relative_tolerance ≈ 1e-8
        @test solver.absolute_tolerance ≈ 0.0
    end


    @testset "solve equation diagonal" begin
        # test if it can solve equation for diagonal matrix problem (lumped matrix)
        lhs = get_reference_lhs(1, "u_1")
        rhs = get_reference_rhs(1, "u_1")
        unknowns_handler = get_unknowns(0)
        WaveCore.update_preconditioner!(solver, lhs, "u_1")
        
        @test check_reference_csv(
            "ref_solver",
            "t_1_step_1_u_1.csv", 
            WaveCore.calculate_solution(solver, "u_1", lhs, rhs, unknowns_handler)
        )
    end

    @testset "solve equation symmetric" begin
        # test if it can solve equation for diagonal matrix problem (lumped matrix)
        lhs = get_reference_lhs(2, "p")
        rhs = get_reference_rhs(2, "p")
        unknowns_handler = get_unknowns(0)
        WaveCore.update_preconditioner!(solver, lhs, "p")

        @test check_reference_csv(
            "ref_solver",
            "t_1_step_2_p.csv", 
            WaveCore.calculate_solution(solver, "p", lhs, rhs, unknowns_handler)
        )
    end 
end