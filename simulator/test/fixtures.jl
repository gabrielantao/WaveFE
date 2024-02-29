struct InputDataFixture
    # brief description for the current fixture
    description::String
    hdf_data
    simulation_data
    domain_conditions_data

    function InputDataFixture(description, case_folder)
        # input all the relevant data to build the model 
        new(
            description,
            h5open(joinpath(case_folder, SIMULATION_MESH_FILENAME), "r"),
            TOML.parsefile(joinpath(case_folder, SIMULATION_INPUT_FILENAME)),
            TOML.parsefile(joinpath(case_folder, DOMAIN_CONDITIONS_FILENAME))
        )
    end
end

const input_square_cavity_triangles = InputDataFixture(
    "Square cavity triangle elements",
    joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity") 
)