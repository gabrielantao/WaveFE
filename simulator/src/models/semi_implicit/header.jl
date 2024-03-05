export MODEL_NAME, MODEL_UNKNOWNS

const MODEL_NAME = "CBS semi-implicit"
const MODEL_UNKNOWNS = ["u_1", "u_2", "u_3", "p"]


"""Additional parameters from the input file"""
struct ModelSemiImplicitParameters <: ModelParameters
    transient::Bool
    safety_Δt_factor::Float64
    adimensionals::Dict{String, Float64}
end