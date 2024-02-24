# import all models created for the simulator
using ModuleSemiImplicit


"""Get a registered model implemented in the directory models"""
function build_model(input_data, simulation_data, domain_conditions_data)
    model_name = simulation_data["simulation"]["model"]
    if model_name == MODEL_NAME_SEMI_IMPLICIT
        return ModelSemiImplicit(input_data, simulation_data, domain_conditions_data)
    # elseif name == "NEW MODEL HERE"
        # The one that implements a new model must include if here in this function
    end
end