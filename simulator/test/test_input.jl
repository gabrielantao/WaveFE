@testset "import simulation data" begin
    @test read(input_square_cavity_triangles.hdf_data["mesh/dimension"]) == 2
    regression_test(
        "ref_input", 
        "nodes_positions.txt", 
        read(input_square_cavity_triangles.hdf_data["mesh/nodes/positions"])
    )
    regression_test(
        "ref_input", 
        "nodes_domain_conditions.txt", 
        read(input_square_cavity_triangles.hdf_data["mesh/nodes/domain_condition_groups"])
    )
    regression_test(
        "ref_input", 
        "triangles_connectivity.txt", 
        read(input_square_cavity_triangles.hdf_data["mesh/triangles/connectivity"])
    )
    regression_test(
        "ref_input", 
        "simulation_data.bson", 
        input_square_cavity_triangles.simulation_data
    )
    regression_test(
        "ref_input", 
        "domain_conditions_data.bson", 
        input_square_cavity_triangles.domain_conditions_data
    )
end

