"""
Check the obtained values against the reference values.

Ghia, U., Ghia, K.N. and Shin, C.T. (1982) 
High-Resolutions for Incompressible Flow Using the Navier-Stokes Equations and a Multigrid Method. 
Journal of Computational Physics, 48, 387-411. 
"""
function check_ghia_reference(case::ValidationCase, tolerance::Float64=0.05)
    case_folder = joinpath(WAVE_SIMULATOR_TEST_CASE_PATH, case.folder)
    result_filepath = joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME)
    # get the reference positions and values
    reference_u_1 = readdlm(
        joinpath(case_folder, WaveCore.REFERENCE_PATH, "ghia_u_1.csv"), 
        ',', 
        Float64, 
        '\n'
    )
    reference_u_2 = readdlm(
        joinpath(case_folder, WaveCore.REFERENCE_PATH, "ghia_u_2.csv"), 
        ',', 
        Float64, 
        '\n'
    )
    # when get ghia_u_1 the positions are the middle vertical line (positions y)
    # when get ghia_u_2 the positions are the middle horizontal line (positions x)
    ref_positions = Dict("u_1" => reference_u_1[:, 1], "u_2" => reference_u_2[:, 1])
    ref_values = Dict("u_1" => reference_u_1[:, 2], "u_2" => reference_u_2[:, 2])

    # get the obtained result and
    # filter indices for the middle vertical and horizontal lines
    result = h5open(result_filepath, "r")
    result_positions = read(result["/mesh/nodes/positions/t_0"])
    indices_u_1 = findall(x -> x ≈ 0.5, result_positions[1, :])
    indices_u_2 = findall(y -> y ≈ 0.5, result_positions[2, :])

    # need to concatenate positions and result in the same matrix 
    # in order to sort the positions (and values) to create the interpolation functions
    last_timestep = read(result["/total_steps"])
    sorted_u_1 = hcat(
        result_positions[2, indices_u_1], 
        read(result["/result/u_1/t_$last_timestep"])[indices_u_1]
    )
    sorted_u_1 = sorted_u_1[sortperm(sorted_u_1[:, 1]), :]
    sorted_u_2 = hcat(
        result_positions[1, indices_u_2], 
        read(result["/result/u_2/t_$last_timestep"])[indices_u_2]
    )
    sorted_u_2 = sorted_u_2[sortperm(sorted_u_2[:, 1]), :]

    # create the functions to interpolate the reference result using obtained result
    interpolate_result = Dict(
        "u_1" => linear_interpolation(sorted_u_1[:, 1], sorted_u_1[:, 2]),
        "u_2" => linear_interpolation(sorted_u_2[:, 1], sorted_u_2[:, 2])
    )

    for unknown in case.checked_unknonws
        obtained = [interpolate_result[unknown](position) for position in ref_positions[unknown]]
        @test isapprox(obtained, ref_values[unknown], rtol=tolerance)
    end
end