"""
This function compares the vortex shedding of reference that describes 
the vertical velocities at the end of channel (right end of mesh)

reference:
Characteristic-based-split(CBS) algorithm for incompressible flow problems with heat transfer
N. Massarotti, P Nithiarasu, O.C. Zienkiewics
"""
function check_centered_circle_reference(case::ValidationCase, tolerance::Float64=0.05)
    case_folder = joinpath(WAVE_SIMULATOR_TEST_CASE_PATH, case.folder)
    result_filepath = joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME)

    # get the obtained result and
    # filter indices for the middle vertical and horizontal lines
    result = h5open(result_filepath, "r")
    result_positions = read(result["/mesh/nodes/positions/t_0"])
    
    # index of measure point in the mesh (x=5.0, y=2.0)
    index = 5

    senoid = [read(result["/result/u_2/t_$(timestep)"])[index] for timestep=0:2:600]

    # TODO: calculate the admensional timestep for the simulation and save to output file
    # TODO: calculate the maximum or minimum points distance (period of vortex) and compare to reference

    # open("delim_file.csv", "w") do io
    #     writedlm(io, senoid)
    # end
    # @test isapprox(u_1, parabola(y), rtol=tolerance)
end