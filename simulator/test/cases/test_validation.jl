# TODO: move this test to validation tests files
@testset "model semi implicit" begin
    run_validation_case("square_cavity_100")

    # TODO: it should run the checking fase for the results (AKA regression test)
    # for the group of interest and compare with the reference data
end