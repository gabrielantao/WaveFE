"""
This function compares the parabola of reference that describes the profile of flow 
at the end of the mesh (right end of mesh)

reference:
Nithiarasu, P. and Lewis, Roland and Seetharamu, K.N.
Fundamentals of the finite element method for heat and mass transfer. 
2nd edition, pag 221, Figure 7.21
"""
function check_channel_reference(case::ValidationCase, tolerance::Float64=0.05)
    case_folder = joinpath(WAVE_SIMULATOR_TEST_CASE_PATH, case.folder)
    result_filepath = joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME)

    # get the reference positions and values
    # this parabola was obtained fitting the digitilized data for reference parabola
    parabola(y) = 5.443864978 * (y - y .^ 2.0)

    # get the obtained result and
    # filter indices for the middle vertical and horizontal lines
    result = h5open(result_filepath, "r")
    result_positions = read(result["/mesh/nodes/positions/t_0"])
    last_timestep = read(result["/total_steps"])
    indices_u_1 = findall(x -> x ≈ 15.0, result_positions[1, :])
    y = result_positions[2, indices_u_1]
    u_1 = read(result["/result/u_1/t_$last_timestep"])[indices_u_1]

    @test isapprox(u_1, parabola(y), rtol=tolerance)
end