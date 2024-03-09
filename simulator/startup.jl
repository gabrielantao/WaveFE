# This is just a script to be used as startup for julia interactive shell
# the interactive can be used to run tests

# NOTE: find for the real julia startup file by typing:
# pixi run find $WAVE_PATH_ROOT/.pixi/env -name startup.jl

println("Running interactive shell from: $(pwd())")
println("Pre-imported packages:")
println("- Revise")
println("- ReTest")

using Revise
using ReTest
