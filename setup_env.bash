# put the modules in the the Julia path path
export JULIA_LOAD_PATH="$PIXI_PACKAGE_ROOT:$JULIA_LOAD_PATH"

# put the test packages in the Julia path
export JULIA_LOAD_PATH="$PIXI_PACKAGE_ROOT/simulator/test:$JULIA_LOAD_PATH"
