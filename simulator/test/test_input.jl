@testset "import simulation data" begin

    # TODO: change these tests to import as a SimulationCase
    # TODO: change the name of the fixture to case_square_cavity
    #case = WaveCore.load_simulation_case(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity"))
    #generate_cached_data(case)
    # @test read(case_square_cavity_triangles.hdf_data["mesh/dimension"]) == 2

    # @test check_reference_csv(
    #     "ref_input", 
    #     "nodes_positions.csv", 
    #     [column for column in eachcol(read(case_square_cavity_triangles.hdf_data["mesh/nodes/positions"]))]
    # )
    # @test check_reference_csv(
    #     "ref_input", 
    #     "nodes_domain_conditions.csv", 
    #     read(case_square_cavity_triangles.hdf_data["mesh/nodes/domain_condition_groups"])
    # )
    # @test check_reference_csv(
    #     "ref_input", 
    #     "triangles_connectivity.csv", 
    #     [column for column in eachcol(read(case_square_cavity_triangles.hdf_data["mesh/triangles/connectivity"]))]
    # )
    # check_reference_data(
    #     "ref_input", 
    #     "simulation_data.bson", 
    #     case_square_cavity_triangles.simulation_data
    # )
    # check_reference_data(
    #     "ref_input", 
    #     "domain_conditions_data.bson", 
    #     case_square_cavity_triangles.domain_conditions_data
    # )
end

