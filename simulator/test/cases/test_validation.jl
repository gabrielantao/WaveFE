include("backward_facing_step/reference/step_reference.jl")
include("square_cavity_100/reference/ghia_reference.jl")
include("rectangular_channel/reference/channel_reference.jl")


@testset "validation model semi implicit" begin
    @testset "square_cavity_100" begin
        case = ValidationCase(
            ModuleSemiImplicit.MODEL_NAME, "square_cavity_100", ["u_1", "u_2"]
        )
        run_validation_case(case)
        check_reference(case)
        check_ghia_reference(case)
    end

    @testset "square_cavity_400" begin
        case = ValidationCase(
            ModuleSemiImplicit.MODEL_NAME, "square_cavity_400", ["u_1", "u_2"]
        )
        run_validation_case(case)
        check_reference(case)
        # NOTE: in the reference Ghia et al data the 6th point is an outlier
        # so the value was replaced by the calculated by the simulation just
        # to keep the cases with same number of reference points
        check_ghia_reference(case)
    end

    @testset "square_cavity_1000" begin
        case = ValidationCase(
            ModuleSemiImplicit.MODEL_NAME, "square_cavity_1000", ["u_1", "u_2"]
        )
        run_validation_case(case)
        check_reference(case)
        check_ghia_reference(case)
    end

    @testset "rectangular_channel" begin
        case = ValidationCase(
            ModuleSemiImplicit.MODEL_NAME, "rectangular_channel", ["u_1"]
        )
        run_validation_case(case)
        check_reference(case)
        check_channel_reference(case)
    end

    @testset "backward_facing_step" begin
        case = ValidationCase(
            ModuleSemiImplicit.MODEL_NAME, "backward_facing_step", ["u_1", "u_2"]
        )
        run_validation_case(case)
        check_reference(case)
        check_step_reference(case)
    end
end
