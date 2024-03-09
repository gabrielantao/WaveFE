# TODO [implement better debugging tools]
## this should be able to check any set of timesteps 
function check_reference_hdf(
    case_folder_name::String,
    unknown::String,
    rtol::Float64=0.001, 
    atol::Float64=0.0,
    elementwise::Bool=true
)
    reference_filepath = joinpath(
        WAVE_SIMULATOR_TEST_CASE_PATH, case_folder_name, WaveCore.REFERENCE_PATH, WaveCore.RESULT_FILENAME
    )
    reference_data = h5open(reference_filepath , "r")
    obtained_filepath = joinpath(
        WAVE_SIMULATOR_TEST_CASE_PATH, case_folder_name, WaveCore.CACHE_PATH, WaveCore.RESULT_PATH, WaveCore.RESULT_FILENAME
    )
    obtained_data = h5open(obtained_filepath , "r")
    MAXIMUM_DIFF_TO_SHOW = 10
    must_regenerate = PARSED_ARGS["regenerate-result"]

    # get last timestep for the reference
    ref_last_timestep = read(reference_data["/total_steps"])
    reference = read(reference_data["/result/$unknown/t_$ref_last_timestep"])
    # get last timestep for the obtained 
    last_timestep = read(obtained_data["/total_steps"])
    obtained = read(obtained_data["/result/$unknown/t_$last_timestep"])
    if !isfile(reference_filepath)
        mkpath(dirname(reference_filepath))
        cp(obtained_filepath, reference_filepath)
        @info "File not found in the reference folder, created: $filepath"
        return false
    end
    if size(reference) != size(obtained)
        @error "The values for the variable $unknown don't have the same size\nreference=$(size(reference)) obtained=$(size(obtained))"
        return false
    end
    if ref_last_timestep != last_timestep
        @info "The reference and the obtained timestep don't have the same last time step\n reference=$ref_last_timestep obtained=$last_timestep "
    end
    if elementwise
        diff_positions = isapprox.(obtained, reference, rtol=rtol, atol=atol)
        if all(diff_positions)
            return true
        else
            all_diff_positions = findall(.!diff_positions)
            total_diff = length(all_diff_positions)
            diff_message = "Obtained and reference differs in $(total_diff) places.\n"
            diff_message = diff_message * "obtained != reference:\n"
            for i in range(1, total_diff)
                if i > MAXIMUM_DIFF_TO_SHOW
                    diff_message = diff_message * "and so on..."
                    break
                end
                diff_pos = all_diff_positions[i]
                obtained_i = obtained[diff_pos]
                reference_i = reference[diff_pos]
                row = "at position $(Tuple(diff_pos)) => $obtained_i != $reference_i\n"
                diff_message = diff_message * row
            end
            # check if it need to be regenerated
            if must_regenerate
                cp(obtained_filepath, reference_filepath, force=true)
                @info "Updated result: $reference_filepath"
            else
                @error diff_message
            end
            return false
        end               
    else
        return isapprox(obtained, reference, rtol=rtol, atol=atol)
    end    

end


@testset "model semi implicit" begin
    case_folder_name = "square_cavity_100"

    run_validation_case(case_folder_name)

    @test check_reference_hdf(
        case_folder_name,
        "u_1"
    )
    @test check_reference_hdf(
        case_folder_name,
        "u_2"
    )

    # TODO [add validation cases for the semi implicit]
    ## add plot here
end