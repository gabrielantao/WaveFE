@testset "import simulation data" begin
    @test read(input_square_cavity_triangles.hdf_data["mesh/dimension"]) == 2
    @test check_reference_csv(
        "ref_input", 
        "nodes_positions.csv", 
        read(input_square_cavity_triangles.hdf_data["mesh/nodes/positions"])
    )
    @test check_reference_csv(
        "ref_input", 
        "nodes_domain_conditions.csv", 
        read(input_square_cavity_triangles.hdf_data["mesh/nodes/domain_condition_groups"])
    )
    @test check_reference_csv(
        "ref_input", 
        "triangles_connectivity.csv", 
        read(input_square_cavity_triangles.hdf_data["mesh/triangles/connectivity"])
    )
    check_reference_data(
        "ref_input", 
        "simulation_data.bson", 
        input_square_cavity_triangles.simulation_data
    )
    check_reference_data(
        "ref_input", 
        "domain_conditions_data.bson", 
        input_square_cavity_triangles.domain_conditions_data
    )
end

