# import all models created for the simulator
include("./semi_implicit/model.jl")
using .ModuleSemiImplicit


"""Get a registered model implemented in the directory models"""
function build_model(folder, input_data, simulation_data, domain_conditions_data)
    model_name = simulation_data["simulation"]["model"]
    if model_name == ModuleSemiImplicit.MODEL_NAME
        return ModelSemiImplicit(folder, input_data, simulation_data, domain_conditions_data)
    # elseif name == "NEW MODEL HERE"
        # The one that implements a new model must include if here in this function
    end
end
