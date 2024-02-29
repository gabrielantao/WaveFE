@testset "load elements data" begin
    # TODO [implement one dimensional elements]
    ## implement tests

    @testset "bidimensional elements" begin
        data = ExampleInputData()

        # load the elements for the mesh 
        triangles = Wave.load_triangles(data.hdf_input, data.simulation)
      
        @test Wave.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3
        @test all([isempty(element.b) || isempty(element.c) for element in triangles.elements])
        @test all([isnan(element.area) || isnan(element.Δt) for element in triangles.elements])

        # load the quadrilaterals of the mesh
        quadrilaterals = Wave.load_quadrilaterals(data.hdf_input, data.simulation)
    
        @test Wave.get_total_elements(quadrilaterals) == 0
        @test quadrilaterals.nodes_per_element == 4
    end  

    # TODO [implement three dimensional elements]
    ## implement tests

    # TODO [implement hybrid mesh]
    ## check how it behaves when load hybrid meshs
end


@testset "load elements data" begin
    # TODO [implement one dimensional elements]
    ## implement tests

    @testset "bidimensional elements" begin
        data = ExampleInputData()

        # load the elements for the mesh 
        triangles = Wave.load_triangles(data.hdf_input, data.simulation)
      
        @test Wave.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3
        @test all([isempty(element.b) || isempty(element.c) for element in triangles.elements])
        @test all([isnan(element.area) || isnan(element.Δt) for element in triangles.elements])

        # load the quadrilaterals of the mesh
        quadrilaterals = Wave.load_quadrilaterals(data.hdf_input, data.simulation)
    
        @test Wave.get_total_elements(quadrilaterals) == 0
        @test quadrilaterals.nodes_per_element == 4
    end  

    # TODO [implement three dimensional elements]
    ## implement tests

    # TODO [implement hybrid mesh]
    ## check how it behaves when load hybrid meshs
end

@testset "load mesh data" begin
    # TODO [implement one dimensional elements]
    ## implement tests
    mock_mesh_input_data = Dict()
    @testset "bidimensional mesh" begin
        # check all areas and deltat as NaN and empty b and c
        # just mock the values for the elements
        mock_simulation_data = Dict("mesh" => Dict("interpolation_order" => 1))
        mock_mesh_input_data = Dict(
            "mesh" => Dict(
                "dimension" => 2,
                "nodes" => Dict(
                    "physical_groups" => Int64[],
                    "geometrical_groups" => Int64[],
                    "domain_condition_groups" => Int64[],
                    "positions" => Float64[],
                    "velocities" => Float64[],
                    "accelerations" => Float64[]
                )
            )        
        )
        mesh = Wave.load_mesh(mock_mesh_input_data, mock_simulation_data)
        @test mesh.dimension == Wave.BIDIMENSIONAL::Dimension
        @test mesh.interpolation_order == Wave.ORDER_ONE::InterpolationOrder
        @test mesh.must_refresh == true
    end

    # TODO [implement three dimensional elements]
    ## implement tests
end