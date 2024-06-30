@testset "elements quadrilaterals" begin 
    quadrilaterals = WaveCore.load_quadrilaterals(
        case_square_cavity_triangles.mesh_data
    )

    # TODO [implement quadrilateral elements]
    # load the quadrilaterals of the mesh (from a input file that has quadrilaterals)
    @testset "quadrilaterals loaded" begin
    end  

    @testset "get quadrilaterals properties" begin
    end

    @testset "calculate quadrilaterals properties" begin
    end
end