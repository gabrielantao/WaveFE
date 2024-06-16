"""
Check the obtained values against the reference values.

The reference values was extracted from the one presented in: 
Nithiarasu, P. and Lewis, Roland and Seetharamu, K.N.
Fundamentals of the finite element method for heat and mass transfer. 
2nd edition, pag 229, Figure 7.31

The original data is from:
Denham, M.K. and Patrick, M.A. (1974) 
Laminar Flow over a Downstream-Facing, Step in a Two-Dimensional Flow Channel. 
Transactions of the Institution of Chemical Engineers, 52, 361-367. 
"""
function check_step_reference(case::ValidationCase, tolerance::Float64=0.1)
    case_folder = joinpath(WAVE_SIMULATOR_TEST_CASE_PATH, case.folder)
    result_filepath = joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME)
    
    all_reference_results = [
        (4.00, "result_x_4_00.csv"),
        (4.88, "result_x_4_88.csv"),
        (6.11, "result_x_6_11.csv"),
        (8.17, "result_x_8_17.csv"),
        (14.29, "result_x_14_29.csv"),
    ]

    # get the obtained result and
    # filter indices for the middle vertical and horizontal lines
    result = h5open(result_filepath, "r")
    result_positions = read(result["/mesh/nodes/positions/t_0"])

    # check for each vertical listed positions
    for (ref_x, reference_filename) in all_reference_results 
        # get the indices of nodes in that vertical measured vertical lines
        indices_u_1 = findall(x -> x ≈ ref_x, result_positions[1, :])

        # need to concatenate positions and result in the same matrix 
        # in order to sort the positions (and values) to create the interpolation functions
        last_timestep = read(result["/total_steps"])
        sorted_u_1 = hcat(
            result_positions[2, indices_u_1], 
            read(result["/result/u_1/t_$last_timestep"])[indices_u_1]
        )
        sorted_u_1 = sorted_u_1[sortperm(sorted_u_1[:, 1]), :]
    
        # create the functions to interpolate the reference result using obtained result
        interpolate_result = linear_interpolation(sorted_u_1[:, 1], sorted_u_1[:, 2])

        # get the reference positions and values
        reference_u_1 = readdlm(
            joinpath(case_folder, WaveCore.REFERENCE_PATH, reference_filename), 
            ',', 
            Float64, 
            '\n',
            skipstart=1
        )

        # get the reference values for y positions and compare with the obtained
        ref_positions = reference_u_1[:, 1]
        ref_values = reference_u_1[:, 2]
        obtained = [interpolate_result(position) for position in ref_positions]
        @test isapprox(obtained, ref_values, rtol=tolerance)
    end
end