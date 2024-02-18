# import all models created for the simulator
using ModuleSemiImplicit


"""Get a registered model implemented in the directory models"""
function build_model(input_data, simulation_parameters)
    model_name = simulation_parameters["simulation"]["model"]
    if model_name == "CBS Semi-Implicit"
        return ModelSemiImplicit(input_data, simulation_parameters)
    # elseif name == "NEW MODEL HERE"
        # The one that implements a new model must include if here in this function
    end
end