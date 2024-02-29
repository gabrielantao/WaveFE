# example "fixture" for the tests
struct ExampleInputData
    hdf_input
    simulation
    domain_conditions

    function ExampleInputData()
        case_folder = joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity") 
        # input all the relevant data to build the model 
        new(
            h5open(joinpath(case_folder, SIMULATION_MESH_FILENAME), "r"),
            TOML.parsefile(joinpath(case_folder, SIMULATION_INPUT_FILENAME)),
            TOML.parsefile(joinpath(case_folder, DOMAIN_CONDITIONS_FILENAME))
        )
    end
end