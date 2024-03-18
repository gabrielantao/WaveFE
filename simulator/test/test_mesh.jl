@testset "mesh data" begin
    @testset "mesh unidimensional" begin
        # TODO [implement one dimensional elements]
        ## implement tests
    end

    @testset "mesh bidimensional" begin
        mesh = WaveCore.build_mesh(case_square_cavity_triangles.mesh_data)

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
        @test mesh.must_refresh == true

        # check baseic nodes and elements properties
        # this case the get_containers return just the triangles container
        # 
        @test WaveCore.get_total_nodes(mesh.nodes) == 2601
        element_containers = WaveCore.get_containers(mesh.elements)
        @test length(element_containers) == 1 
        triangles = element_containers[1]
        @test triangles isa WaveCore.TrianglesContainer
        @test WaveCore.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3

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
                case_square_cavity_triangles.simulation_data.parameter.parameters["Re"], 
                case_square_cavity_triangles.simulation_data.simulation.safety_Δt_factor 
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