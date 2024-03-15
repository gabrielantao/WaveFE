@testset "output simulation data" begin
    output_cache_folder = joinpath(WAVE_SIMULATOR_TEST_PATH, "ref_output", WaveCore.CACHE_PATH)
    output_handler = WaveCore.build_output_handler(
        output_cache_folder,
        input_square_cavity_triangles.simulation_data
    )
    unknowns_handler = WaveCore.UnknownsHandler(
        Dict("u_1" => fill(1.0, 3), "u_2" => fill(2.0, 3), "p" => fill(3.0, 3)),
        Dict("u_1" => zeros(3), "u_2" => zeros(3), "p" => zeros(3)),
        Dict("u_1" => true, "u_2" => true, "p" => true),
        Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
        Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
    )
    WaveCore.write_result_data(output_handler, unknowns_handler, 100)
    WaveCore.write_additional_data(output_handler, true, 200, 1000.0)
    # write some debug data
    output_handler.debug_file["some_debug_data"] = fill(4.0, 5)
    WaveCore.close_files(output_handler)
    
    result_path = joinpath(output_cache_folder, WaveCore.RESULT_PATH)
    result_file = h5open(joinpath(result_path, WaveCore.RESULT_FILENAME), "r")
    debug_file = h5open(joinpath(result_path, WaveCore.DEBUG_FILENAME), "r")

    # check basic data
    @test read(result_file["version"]) == "1.0"
    @test read(result_file["description"]) == "Cavity test case with Re = 100"
    @test read(debug_file["version"]) == "1.0"
    @test read(debug_file["description"]) == "Cavity test case with Re = 100"

    # check if data of unknonws were writen in the output
    @test read(debug_file["some_debug_data"]) ≈ fill(4.0, 5)
    @test read(result_file["result/u_1/t_100"]) ≈ [1.0, 1.0, 1.0]
    @test read(result_file["result/u_2/t_100"]) ≈ [2.0, 2.0, 2.0]
    # should not save the unknonw p because in the simulation file it's not set in the
    # section "output" of the example simulation.toml (imported by fixture input_square_cavity_triangles)
    # as unknonws that should be written in the result files
    @test haskey(result_file, "result/p/t_100") == false

    # check for converged unknonws
    @test read(result_file["convergence/u_1/t_100"]) == true
    @test read(result_file["convergence/u_2/t_100"]) == true
    @test haskey(result_file, "convergence/p/t_100") == false

    # check additional data
    @test read(result_file["success"]) == true
    @test read(result_file["total_steps"]) == 200
    @test read(result_file["total_elapsed_time"]) == 1000.0

    # clean up the files
    rm(output_cache_folder, force=true, recursive=true)

    # TODO [implement mesh movement]
    ## test the function write_mesh_data()
end