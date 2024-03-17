function fixture_case_square_cavity_triangles(case_folder)
    return SimulationCase(
        case_folder,
        true,
        WaveCore.SimulationFileSchema.load_simulation_data(
            joinpath(case_folder, WaveCore.SIMULATION_FILENAME)
        ),
        WaveCore.ConditionsFileSchema.load_domain_conditions_data(
            joinpath(case_folder, WaveCore.DOMAIN_CONDITIONS_FILENAME)
        ),
        BSON.load(
            joinpath(case_folder, "mesh_data.bson"), 
            @__MODULE__
        )[:mesh_data]
    )
end

const case_square_cavity_triangles = fixture_case_square_cavity_triangles(
    joinpath(WAVE_SIMULATOR_TEST_DATA_PATH, "case_square_cavity")
)