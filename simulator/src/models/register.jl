# import all models created for the simulator
include("./semi_implicit/model.jl")
using .ModuleSemiImplicit


"""Get a registered model implemented in the directory models"""
function build_model(simulation_data::SimulationData)
    model_name = simulation_data["simulation"]["model"]
    if model_name == ModuleSemiImplicit.MODEL_NAME
        return ModelSemiImplicit(simulation_data)
    # TODO [implement model with heat transfer]
    # TODO [implement model with chemical spiecies transfer]
    # TODO [implement model with porous media ]
    ## implement other options of models here\
    else
        throw("The model named $model_name is not registered as a model.")
    end
end
