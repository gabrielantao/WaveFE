@testset "elements segments" begin 
    # load the elements for the mesh 
    segments = WaveCore.load_segments(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.simulation_data
    )

    # TODO [implement one dimensional elements]
    ## implement tests
    @testset "segments loaded" begin
    end  

    @testset "get segments properties" begin
    end

    @testset "calculate segments properties" begin
    end

end