@testset "import mesh data" begin
    case_folder = joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity") 
    mesh_data = WaveCore.load_mesh_data(joinpath(case_folder, "square_cavity.msh"))
    
    @test mesh_data.dimension == WaveCore.BIDIMENSIONAL::Dimension

    # check nodes values
    @test mesh_data.nodes.total_nodes == 2129
    @test size(mesh_data.nodes.positions) == (3, 2129)
    @test check_reference_csv(
        "ref_mesh_data",
        "positions.csv", 
        [[x, y, z] for (x, y, z) in eachcol(mesh_data.nodes.positions)]
    )
    @test check_reference_csv(
        "ref_mesh_data",
        "geometrical_groups.csv", 
        mesh_data.nodes.geometrical_groups.groups
    )
    @test mesh_data.nodes.physical_groups.names == Dict(2 => "no-slip", 3 => "reference", 1 => "top")
    @test check_reference_csv(
        "ref_mesh_data",
        "physical_groups.csv", 
        mesh_data.nodes.physical_groups.groups
    )

    # check elements values
    @test mesh_data.elements[1].total_elements == 4088
    @test length(mesh_data.elements) == 1
    @test check_reference_csv(
        "ref_mesh_data",
        "triangles_connectivity.csv", 
        [connectivity for connectivity in eachcol(mesh_data.elements[1].connectivity)]
    )
    @test mesh_data.elements[1].element_type_data.name == "Triangle 3"
    @test mesh_data.elements[1].element_type_data.type == WaveCore.TRIANGLE::ElementType
    @test mesh_data.elements[1].element_type_data.dimension == WaveCore.BIDIMENSIONAL::Dimension
    @test mesh_data.elements[1].element_type_data.interpolation_order == WaveCore.ORDER_ONE::InterpolationOrder
    @test mesh_data.elements[1].element_type_data.nodes_per_element == 3
end