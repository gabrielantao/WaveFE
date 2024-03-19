# function regression_result(case_folder)    
# end
function load_ghia_et_al_reference(case_filepath, Re, velocity_direction)
    # load the reference data
    reference_u_1, header_u_1 = readdlm(
        joinpath(case_filepath, "reference", "ghia_et_al_vx.csv"), ',', Float64, '\n', header=true
    )
    reference_u_2, header_u_2 = readdlm(
        joinpath(case_filepath, "reference", "ghia_et_al_vy.csv"), ',', Float64, '\n', header=true
    )
    column_index = findfirst(item -> item == Re, [100, 400, 1000, 3200, 5000, 7500, 10000])
    if isnothing(column_index)
        throw("The Reynolds number $Re is not presented in available reference results.")
    else
        # sum 2 because the two first columns are x and y coordinates
        column_index += 2
    end
    if velocity_direction == 1
        # compare vertical central line with the reference result for the u_1
        reference_positions_y_u_1 = reference_u_1[:, 2]
        values = reference_u_1[:, column_index]
        return reference_positions_y_u_1, values
    
    elseif velocity_direction == 2
        # compare horizontal central line with the reference result for the u_2
        reference_positions_x_u_2 = reference_u_2[:, 1]
        values = reference_u_2[:, column_index]
        return reference_positions_x_u_2, values
    else 
        throw("Invalid direction $velocity_direction for velocity reference data.")
    end
end


function plot_ghia_et_al_result()
    VERTICAL_LINE_GROUP = 1 
    HORIZONTAL_LINE_GROUP = 2
    CENTRAL_POINT_GROUP = 3
      # run the checking with the Ghia et al. reference values
    # for the group of nodes interest for vertical central line and horizontal central line
    case_filepath = joinpath(
        WAVE_SIMULATOR_TEST_CASE_PATH, 
        case_folder_name, 
    )
    input_data = h5open(
        joinpath(case_filepath, WaveCore.CACHE_PATH, WaveCore.MESH_FILENAME), "r"
    )
    result_data = h5open(
        joinpath(case_filepath, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME), "r"
    )
    last_timestep = read(result_data["total_steps"])
    u_1 = read(result_data["/result/u_1/t_$last_timestep"])
    u_2 = read(result_data["/result/u_2/t_$last_timestep"])
    
    # check u_1
    group_indices = findall(
        geometrical_group -> geometrical_group == CENTRAL_POINT_GROUP || geometrical_group == VERTICAL_LINE_GROUP,
        read(input_data["/mesh/nodes/geometrical_groups"])
    )
    
    positions_y = read(input_data["/mesh/nodes/positions"])[2, :][group_indices]
    values = u_1[group_indices]
    ref_positions_y, ref_values = load_ghia_et_al_reference(case_filepath, 100, 1)

    println(positions_y)
    println(ref_positions_y)
    # check u_2
    group_indices = findall(
        geometrical_group -> geometrical_group == CENTRAL_POINT_GROUP || geometrical_group == HORIZONTAL_LINE_GROUP,
        read(input_data["/mesh/nodes/geometrical_groups"])
    )
    positions_x = read(input_data["/mesh/nodes/positions"])[1, :][group_indices]
    values = u_2[group_indices]
    ref_positions_x, ref_values = load_ghia_et_al_reference(case_filepath, 100, 2)
    
    # TODO [add validation cases for the semi implicit]
    ## add plot here
end