@testset "import simulation case data" begin
    case_folder = joinpath(WAVE_SIMULATOR_TEST_PATH, "dummy_case")
    case = WaveCore.build_simulation_case(case_folder)

    @test isfile(joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.CACHED_DATA_FILENAME))
    @test isfile(joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.DOMAIN_CONDITIONS_FILENAME))
    @test isfile(joinpath(case_folder, WaveCore.CACHE_PATH, WaveCore.SIMULATION_FILENAME))
    @test isfile(joinpath(case_folder, WaveCore.CACHE_PATH, "square_cavity.msh"))

    # rewrite the files
    case_folder = joinpath(WAVE_SIMULATOR_TEST_PATH, "dummy_case")
    case = WaveCore.build_simulation_case(case_folder)
    # clean up the files
    rm(joinpath(case_folder, WaveCore.CACHE_PATH), force=true, recursive=true)
end

