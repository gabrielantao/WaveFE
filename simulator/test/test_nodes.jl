@testset "nodes" begin
    # load the elements for the mesh 
    nodes = WaveCore.load_nodes(case_square_cavity_triangles.mesh_data)
    
    @testset "nodes loaded" begin
        @test WaveCore.get_total_nodes(nodes) == 2601
        # just check the first and last nodes
        @test nodes.series[1].position ≈ [0.0, 0.0]
        @test nodes.series[2601].position ≈ [1.0, 1.0]
        # static mesh so these values should be zero anyway
        @test all([node.velocity ≈ [0.0, 0.0] for node in WaveCore.get_nodes(nodes)])
        @test all([node.acceleration ≈ [0.0, 0.0] for node in WaveCore.get_nodes(nodes)])
    end
    
    @testset "get nodes properties" begin
        @test WaveCore.get_positions_x(nodes, [1, 53, 52]) ≈ [0.0, 0.0033401432, 0.0]
        @test WaveCore.get_positions_y(nodes, [1, 53, 52]) ≈ [0.0, 0.0033401432, 0.0033401432]
        # this must break because this mesh is bidimensional!
        @test_throws BoundsError WaveCore.get_positions_z(nodes, [1, 53, 52])

        domain_condition_groups = case_square_cavity_triangles.mesh_data.nodes.physical_groups.groups
        @test WaveCore.get_domain_condition_groups(nodes) == domain_condition_groups
    end
    
    @testset "update nodes position" begin
        # this is static mesh so move method shoud just set moved nodes to false
        WaveCore.move!(nodes)
        @test nodes.moved == false
    end
end