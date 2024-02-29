@testset "elements quadrilaterals" begin 
    quadrilaterals = Wave.load_quadrilaterals(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.simulation_data
    )

    # TODO [implement two dimensional elements]
    # load the quadrilaterals of the mesh (from a input file that has quadrilaterals)
    @testset "quadrilaterals loaded" begin
    end  

    @testset "get quadrilaterals properties" begin
    end

    @testset "calculate quadrilaterals properties" begin
    end
end