@testset "elements triangles" begin 
    # load the elements for the mesh 
    triangles = Wave.load_triangles(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.simulation_data
    )

    @testset "triangles loaded" begin
        @test Wave.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3
        @test all([isempty(element.b) || isempty(element.c) for element in triangles.series])
        @test all([isnan(element.area) || isnan(element.Δt) for element in triangles.series])
    end

    @testset "get triangles properties" begin
        @test Wave.get_border_node_ids(triangles.series[1]) == [1, 53, 52]
        @test Wave.get_border_node_ids(triangles.series[5000]) == [2549, 2550, 2601]
        @test Wave.get_edges_node_ids(triangles.series[1]) == [[1, 53], [53, 52], [52, 1]]
    end

end
