module WaveCore

using TOML
using Gmsh
using HDF5
using ProgressMeter
using SparseArrays
using Preconditioners
using IterativeSolvers
using Logging, LoggingExtras

# export the main function of the wave core
export run_simulation


# general core files
include("constants.jl")
include("common.jl")

# the include file schemas and validators
include("../schema/common.jl")
include("../schema/conditions_schema.jl")
include("../schema/simulation_schema.jl")
include("../schema/mesh_schema.jl")
#include("validation.jl")
using .ConditionsFileSchema: DomainConditionsData, load_domain_conditions_data
using .SimulationFileSchema: SimulationData, load_simulation_data


# the core functions
include("unknowns_handler.jl")
include("output.jl")
include("domain_conditions.jl")
include("../mesh/mesh.jl")
include("assembler.jl")
include("solver.jl")
include("base_equation.jl")

# the models, methods, case and simulation functions
include("method.jl")
include("case.jl")
include("simulation.jl")
include("../models/register.jl")


"""Main function of the Wave simulator that runs the simulation"""
function run_simulation(parsed_args)
    simulation = build_simulation(parsed_args["folder"])
    if parsed_args["force-rerun"] || simulation.case.has_changed
        start(simulation, parsed_args["show-progress"])
    #else
        # TODO [add validation cases for the semi implicit]
        ## add log info here saying that it will not run
    end
end

end # module