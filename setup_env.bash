#!/usr/bin/env bash

# put the modules in the the Julia path path
export JULIA_LOAD_PATH="$PIXI_PROJECT_ROOT:$JULIA_LOAD_PATH"

# put the test packages in the Julia path
export JULIA_LOAD_PATH="$PIXI_PROJECT_ROOT/simulator/test:$JULIA_LOAD_PATH"

# add libs for the gmsh
export JULIA_LOAD_PATH="$PIXI_PROJECT_ROOT/.pixi/envs/default/lib/:$JULIA_LOAD_PATH"
