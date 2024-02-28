@testset "smoke" begin
    @test true
end


@testset "can import data" begin
    case_folder = joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity") 
    # input all the relevant data to build the model 
    input_data = h5open(joinpath(case_folder, SIMULATION_MESH_FILENAME), "r")
    simulation_data = TOML.parsefile(joinpath(case_folder, SIMULATION_INPUT_FILENAME))
    domain_conditions_data = TOML.parsefile(joinpath(case_folder, DOMAIN_CONDITIONS_FILENAME))

    @test read(input_data["mesh/dimension"]) == 2
    regression_test("ref_input", "nodes_positions.txt", read(input_data["mesh/nodes/positions"]))
    regression_test("ref_input", "nodes_domain_conditions.txt", read(input_data["mesh/nodes/domain_condition_groups"]))
    regression_test("ref_input", "triangles_connectivity.txt", read(input_data["mesh/triangles/connectivity"]))
    regression_test("ref_input", "simulation_data.bson", simulation_data)
    regression_test("ref_input", "domain_conditions_data.bson", domain_conditions_data)
    
    close(input_data)
end

