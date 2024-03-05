module WaveCore

using HDF5
using SparseArrays
using Preconditioners
using IterativeSolvers

include("constants.jl")
include("common.jl")
include("unknowns_handler.jl")
include("output.jl")
include("domain_conditions.jl")
include("../mesh/mesh.jl")
include("assembler.jl")
include("solver.jl")
include("base_equation.jl")

end # module