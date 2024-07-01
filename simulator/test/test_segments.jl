@testset "elements segments" begin 
    # load the elements for the mesh 
    segments = WaveCore.load_segments(
        case_square_cavity_triangles.mesh_data, 
    )

    # TODO [implement segment elements]
    ## implement tests
    @testset "segments loaded" begin
    end  

    @testset "get segments properties" begin
    end

    @testset "calculate segments properties" begin
    end

end