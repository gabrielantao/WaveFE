@testset "import domain conditions data" begin
    domain_conditions = Wave.load_domain_conditions(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.domain_conditions_data
    )
    println(domain_conditions.indices)

    for unknown_type in keys(domain_conditions.indices)
        @test check_reference_csv(
            "ref_domain_conditions",
            "indices_$(unknown_type[1])_$(Int(unknown_type[2])).csv", 
            domain_conditions.indices[unknown_type]
        )
        @test check_reference_csv(
            "ref_domain_conditions",
            "values_$(unknown_type[1])_$(Int(unknown_type[2])).csv", 
            domain_conditions.values[unknown_type]
        )
    end
end