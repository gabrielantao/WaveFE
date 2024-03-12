# register the test cases for the CBS semi-implicit model
@test_case ValidationCase(ModuleSemiImplicit.MODEL_NAME, "square_cavity_100", ["u_1", "u_2"])
# TODO [add validation cases for the semi implicit]
## these tests are broken fix this, it breaks at the first timestep
## AssertionError: all(isfinite, unknowns_handler.values[unknown])
# @test_case ValidationCase(ModuleSemiImplicit.MODEL_NAME, "square_cavity_400", ["u_1", "u_2"])
# @test_case ValidationCase(ModuleSemiImplicit.MODEL_NAME, "square_cavity_1000", ["u_1", "u_2"])