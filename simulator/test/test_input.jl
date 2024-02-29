@testset "smoke" begin
    @test true
end


@testset "import simulation data" begin
    data = ExampleInputData()

    @test read(data.hdf_input["mesh/dimension"]) == 2
    regression_test(
        "ref_input", 
        "nodes_positions.txt", 
        read(data.hdf_input["mesh/nodes/positions"])
    )
    regression_test(
        "ref_input", 
        "nodes_domain_conditions.txt", 
        read(data.hdf_input["mesh/nodes/domain_condition_groups"])
    )
    regression_test(
        "ref_input", 
        "triangles_connectivity.txt", 
        read(data.hdf_input["mesh/triangles/connectivity"])
    )
    regression_test("ref_input", "simulation_data.bson", data.simulation)
    regression_test("ref_input", "domain_conditions_data.bson", data.domain_conditions)
end

