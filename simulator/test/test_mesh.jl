@testset "mesh data" begin
    @testset "mesh unidimensional" begin
        # TODO [implement one dimensional elements]
        ## implement tests
    end

    @testset "mesh bidimensional" begin
        mesh = Wave.load_mesh(
            input_square_cavity_triangles.hdf_data, 
            input_square_cavity_triangles.simulation_data
        )
        
        # check mesh proeprties
        @test mesh.dimension == Wave.BIDIMENSIONAL::Dimension
        @test mesh.interpolation_order == Wave.ORDER_ONE::InterpolationOrder
        @test mesh.must_refresh == true

        # check baseic nodes and elements properties
        @test Wave.get_total_nodes(mesh.nodes) == 2601
        triangles, quadrilaterals = Wave.get_containers(mesh.elements)
        @test triangles isa Wave.TrianglesContainer || quadrilaterals isa Wave.QuadrilateralsContainer
        @test Wave.get_total_elements(triangles) == 5000
        @test triangles.nodes_per_element == 3
        @test Wave.get_total_elements(quadrilaterals) == 0
        @test quadrilaterals.nodes_per_element == 4


        @testset "calculate triangles properties" begin
            # TODO: maybe this could be done just by calling the update_elements! of the mesh
            Wave.update_areas!(mesh.elements.triangles, mesh.nodes)
            Wave.update_shape_coeficients!(mesh.elements.triangles, mesh.nodes)
            
            @test check_reference_csv(
                "ref_mesh",
                "triangle_areas.csv", 
                [element.area for element in mesh.elements.triangles.series]
            )
            @test check_reference_csv(
                "ref_mesh",
                "triangle_coefficient_b.csv", 
                [element.b for element in mesh.elements.triangles.series]
            )
            @test check_reference_csv(
                "ref_mesh",
                "triangle_coefficient_c.csv", 
                [element.c for element in mesh.elements.triangles.series]
            )

            # TODO: it needs the domain conditions applied (or mocked here)
            # Wave.update_local_time_interval!(
            #     mesh.elements.triangles, 
            #     mesh.nodes, 
            #     unknowns_handler,
            #     input_square_cavity_triangles.simulation_data["parameter"]["Re"], 
            #     input_square_cavity_triangles.simulation_data["simulation"]["safety_dt_factor"]
            # )
            # regression_test(
            #     "ref_mesh",
            #     "triangle_coefficient_c.txt", 
            #     [element.Δt for element in mesh.elements.triangles.series]
            # )
        end

        # static mesh does nothing in update 
        # moving mesh updates the triangles and/or rebuild (remesh) the mesh elements
        Wave.update!(mesh)
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