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


# TODO: remove this after get all tests done or just get a tiny hdf5 instead of this huge one
function get_input_LHS_fixture(case_folder, step)
    data = h5open(joinpath(case_folder, "debug.hdf5"), "r")
    # offset 1 position because all indices started at zero (Python generated)
    indices = read(data["/t_0/step $step/lhs_assembled/indices"]) .+ 1
    values = read(data["/t_0/step $step/lhs_assembled/values"])
    # println(typeof(indices[1, :]))
    # println(size(values))
    
    # input all the relevant data to build the model 
    return sparse(Vector{Int64}(indices[1, :]), Vector{Int64}(indices[2, :]), values)
end


const reference_lhs_step1_data = get_input_LHS_fixture(
    joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity"), 1
)

const reference_lhs_step2_data = get_input_LHS_fixture(
    joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity"), 2
)