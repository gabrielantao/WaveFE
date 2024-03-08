@testset "semi implicit" begin
    function get_unknowns()
        # get the reference data to build a LHS matrix fixture 
        data_filepath = joinpath(
            WAVE_SIMULATOR_TEST_PATH, "data", "case_square_cavity", "results_reference"
        )
        # intermediate velocities loaded here to assemble second step equation
        filepath = joinpath(data_filepath, "t_2_u_1_int.csv")
        u_1 = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_2_u_2_int.csv")
        u_2 = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_2_p.csv")
        p = readdlm(filepath, ',', Float64, '\n')[:, 1]
        # efective velocity of last time step for the old values
        filepath = joinpath(data_filepath, "t_1_u_1_efet.csv")
        u_1_old = readdlm(filepath, ',', Float64, '\n')[:, 1]
        filepath = joinpath(data_filepath, "t_1_u_2_efet.csv")
        u_2_old = readdlm(filepath, ',', Float64, '\n')[:, 1]
        return WaveCore.UnknownsHandler(
            Dict("u_1" => u_1, "u_2" => u_2, "p" => p),
            Dict("u_1" => u_1_old, "u_2" => u_2_old, "p" => p),
            Dict("u_1" => false, "u_2" => false, "p" => false),
            Dict("u_1" => 1e-5, "u_2" => 1e-5, "p" => 1e-5),
            Dict("u_1" => 0.0, "u_2" => 0.0, "p" => 0.0),
        )
    end

    mesh = WaveCore.load_mesh(
        input_square_cavity_triangles.hdf_data, 
        input_square_cavity_triangles.simulation_data
    )
    unknowns_handler = get_unknowns()
    model_parameters = ModelSemiImplicitParameters(
        false, 
        input_square_cavity_triangles.simulation_data["simulation"]["safety_dt_factor"],
        Dict("Re" => input_square_cavity_triangles.simulation_data["parameter"]["Re"])
    )
    # update the parameters for the elements 
    WaveCore.update_elements!(mesh, unknowns_handler, model_parameters)

    
    @testset "assemble equation 1" begin
        equation_one = EquationStepOne(
            ["u_1", "u_2"], input_square_cavity_triangles.simulation_data
        )
        @testset "assemble triangle 1" begin
            result_u_1 = Vector{Vector{Float64}}()
            result_u_2 = Vector{Vector{Float64}}()
            for element in WaveCore.get_elements(mesh.elements.triangles)
                assembled = assemble_element_rhs(equation_one, element, unknowns_handler, model_parameters)
                push!(result_u_1, assembled["u_1"])
                push!(result_u_2, assembled["u_2"])
            end
            @test check_reference_csv(
                "ref_assembling",
                "equation_1_t_2_u_1.csv", 
                result_u_1
            )
            @test check_reference_csv(
                "ref_assembling",
                "equation_1_t_2_u_2.csv", 
                result_u_2
            )
        end  
    end


    @testset "assemble equation 2" begin
        equation_two = EquationStepTwo(
            ["p"], input_square_cavity_triangles.simulation_data
        )
        @testset "assemble triangle 2" begin
            result = Vector{Vector{Float64}}()
            for element in WaveCore.get_elements(mesh.elements.triangles)
                assembled = assemble_element_rhs(equation_two, element, unknowns_handler, model_parameters)
                push!(result, assembled["p"])
            end
            @test check_reference_csv(
                "ref_assembling",
                "equation_2_t_2.csv", 
                result
            )
        end
    end


    @testset "assemble equation 3" begin
        equation_three = EquationStepThree(
            ["u_1", "u_2"], input_square_cavity_triangles.simulation_data
        )
        @testset "assemble triangle 3" begin
            result_u_1 = Vector{Vector{Float64}}()
            result_u_2 = Vector{Vector{Float64}}()
            for element in WaveCore.get_elements(mesh.elements.triangles)
                assembled = assemble_element_rhs(equation_three, element, unknowns_handler, model_parameters)
                push!(result_u_1, assembled["u_1"])
                push!(result_u_2, assembled["u_2"])
            end
            @test check_reference_csv(
                "ref_assembling",
                "equation_3_t_2_u_1.csv", 
                result_u_1
            )
            @test check_reference_csv(
                "ref_assembling",
                "equation_3_t_2_u_2.csv", 
                result_u_2
            )
        end
    end
end