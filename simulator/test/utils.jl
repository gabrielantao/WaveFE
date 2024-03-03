@enum ReferenceFileFormat begin
    CSV = 1
    TXT = 2
    BSON = 3
end


# TODO [implement better debugging tools]
## maybe the better solution is to remove the package ReferenceTests and use the handwritten solution
## then remember to replace all 
function check_reference_data(test_folder_name, filename, obtained)
    mkpath(joinpath(WAVE_SIMULATOR_TEST_PATH, test_folder_name))
    ## if is csv then process the text to csv but save as txt
    # extension = get_reference_data_format(filename)
    @test_reference joinpath(test_folder_name, filename) obtained
end


function get_reference_data_format(filename)
    extension = splitext(filename)[1]
    if extension == "csv"
        return CSV::ReferenceFileFormat
    elseif extension == "txt"
        return TXT::ReferenceFileFormat
    elseif extension == "bson"
        return BSON::ReferenceFileFormat
    else
        throw("Format file $extension not supported as reference data format")
    end
end


# TODO [implement better debugging tools]
## this is just a workaraound for now to get csv as reference file once CSVFile is not compiling
## to use the ReferenceTests package
"""Make a file regression test comparing a vector/matrix with reference values saved in a csv file"""
function check_reference_csv(
    test_folder_name::String, 
    filename::String,
    obtained::AbstractArray, 
    rtol::Float64=0.001, 
    atol::Float64=0.0,
    elementwise::Bool=true
)
    filepath = joinpath(WAVE_SIMULATOR_TEST_PATH, test_folder_name, filename)
    MAXIMUM_DIFF_TO_SHOW = 10
    must_regenerate = PARSED_ARGS["regenerate-result"]
    # force the obtained to be a matrix
    obtained = to_matrix(obtained)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        writedlm(filepath, obtained, ',')
        @info "File not found, created: $filepath"
        return false
    end
    reference = readdlm(filepath, ',', Float64, '\n')
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
                if total_diff > MAXIMUM_DIFF_TO_SHOW
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
                writedlm(filepath, obtained, ',')
                @info "Updated result: $filepath"
            else
                @error diff_message
            end
            return false
        end               
    else
        return isapprox(obtained, reference, rtol=rtol, atol=atol)
    end       
end


# transform a e.g. Vector{Vector{Float64}} into a matrix for the tests
to_matrix(data) = reduce(vcat, transpose(data))