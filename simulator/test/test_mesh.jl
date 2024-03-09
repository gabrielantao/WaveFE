@testset "mesh data" begin
    @testset "mesh unidimensional" begin
        # TODO [implement one dimensional elements]
        ## implement tests
    end

    @testset "mesh bidimensional" begin
        mesh = WaveCore.load_mesh(
            input_square_cavity_triangles.hdf_data, 
            input_square_cavity_triangles.simulation_data
        )

        function get_unknowns()
            # get the reference data to build a LHS matrix fixture 
            data = h5open(joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity", "result.hdf5"), "r")
            u_1 = read(data["/result/t_0/u_1"])
            u_2 = read(data["/result/t_0/u_2"])
            p = read(data["/result/t_0/p"])
            return UnknownsHandler(
                Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
                Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
                Dict("u_1" => false, "u_2" => false, "p" => false),
                Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
                Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
            )
        end
        
        # check mesh proeprties
        @test mesh.dimension == WaveCore.BIDIMENSIONAL::Dimension
        @test mesh.interpolation_order == WaveCore.ORDER_ONE::InterpolationOrder
        @test mesh.must_refresh == true

        # check baseic nodes and elements properties
        @test WaveCore.get_total_nodes(mesh.nodes) == 2601
        triangles, quadrilaterals = WaveCore.get_containers(mesh.elements)
        @test triangles isa WaveCore.TrianglesContainer || quadrilaterals isa WaveCore.QuadrilateralsContainer
        @test WaveCore.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3
        @test WaveCore.get_total_elements(quadrilaterals) == 0
        @test quadrilaterals.nodes_per_element == 4


        @testset "calculate triangles properties" begin
            WaveCore.update_areas!(mesh.elements.triangles, mesh.nodes)
            WaveCore.update_shape_coeficients!(mesh.elements.triangles, mesh.nodes)
            
            @test check_reference_csv(
                "ref_mesh",
                "triangle_areas.csv", 
                [element.area for element in WaveCore.get_elements(mesh.elements.triangles)]
            )
            @test check_reference_csv(
                "ref_mesh",
                "triangle_coefficient_b.csv", 
                [element.b for element in WaveCore.get_elements(mesh.elements.triangles)]
            )
            @test check_reference_csv(
                "ref_mesh",
                "triangle_coefficient_c.csv", 
                [element.c for element in WaveCore.get_elements(mesh.elements.triangles)]
            )

            WaveCore.update_local_time_interval!(
                mesh.elements.triangles, 
                mesh.nodes, 
                get_unknowns(),
                input_square_cavity_triangles.simulation_data["parameter"]["Re"], 
                input_square_cavity_triangles.simulation_data["simulation"]["safety_dt_factor"]
            )
            @test check_reference_csv(
                "ref_mesh",
                "triangle_coefficient_dt.csv", 
                [element.Δt for element in WaveCore.get_elements(mesh.elements.triangles)]
            )
        end

        # static mesh does nothing in update 
        # moving mesh updates the triangles and/or rebuild (remesh) the mesh elements
        WaveCore.update!(mesh)
        @test mesh.must_refresh == false
        @test mesh.nodes.moved == false

        # TODO [implement hybrid mesh]
        ## check how it behaves when load hybrid meshs
    end


    @testset "mesh tridimensional" begin
        # TODO [implement three dimensional elements]
        ## implement tests
        
        # TODO [implement hybrid mesh]
        ## check how it behaves when load hybrid meshs
    end 
end