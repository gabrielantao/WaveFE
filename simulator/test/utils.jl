# TODO: select here the format csv (must be converted), txt, bson
function regression_test(test_folder_name, filename, data)
    mkpath(joinpath(WAVE_SIMULATOR_TEST_PATH, test_folder_name))
    # TODO: if is csv then process the text to csv but save as txt
    @test_reference joinpath(test_folder_name, filename) data
end