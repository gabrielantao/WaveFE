# how to run a test case
## run a case 
`pixi run wave path/to/the/case`
use the `--help` list all options available

## run all test cases
`pixi run test-case name_of_test_case` 
options:
- `-a` run all tests
- `-d` show data about the listed tests
- `-r` force regenerate the reference test results
- `--help` list all options available

## run all unit tests
`pixi run test-unit name_of_test_unit` 
options:
- `-a` run all tests
- `-d` show data about the listed tests
- `-r` force regenerate the reference test results
- `--help` list all options available


# how to add new test cases
- create the folder of the case in `simulator/test/cases/my_test_case`;
- create the mesh file `my_mesh.msh` inside the folder;
- create the mesh file `simulation.toml` inside the folder. Remember to configure the name of the created mesh in this file;
- create the mesh file `conditions.toml` inside the folder, this can be done manually or you can use a script do make things easier if needed;
- add a test in the testcases list `simulator/test/cases/test_validation.jl`. Use the tests already added as example of how to do so. Remeber to register in the `ValidationCase` call the `my_test_case` as the folder of the test;
- run the test to make sure it generates the right result `pixi run test-case my_test_name`. If the test fails at first run you should try to use the current generated result (inside `simulator/test/cases/my_test_case/cache/result`) running the test adding the flag to regenerate the referente result i.e. you can run `pixi run test-case my_test_name -r`;
- then commit and push the result to the repository.

# how to use other mesh formats
Someone could use the MeshIO (Python or Julia version) to convert a mesh to Gmsh format. For now there is no guarantee this is gonna work, so make sure to import the converted mesh in the Gmsh GUI to check if mesh is ok and make the needed modifications.

# how to debug the code
- tip: first check if everything is ok with the mesh, open it somewhere you can visualize or run something that can check the mesh integrity
- tip: add some prints in the code for a quick inspection
- tip: use [Debugger.jl](https://github.com/JuliaDebug/Debugger.jl) to debug if you like it
- tip: `OutputHandler` writes a hdf5 file with debugging file, so if you wanna inspect the arrays and other data you can export data by adding a line `output_handler.debug_file["my_array_label"] = my_data_to_be_saved` where you want to extract data, and then you can open this data outside the simulator (e.g. use matplotlib to see the data)
- if you are using VSCode check [this](https://www.julia-vscode.org/docs/stable/userguide/debugging/) and [this](https://code.visualstudio.com/docs/languages/julia). Basically you can use a directory `.vscode/settings.json` like this:

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "julia",
            "request": "launch",
            "name": "Launch Julia debug",
            "program": "${workspaceFolder}/simulator/src/main.jl",
            "stopOnEntry": false,
            "args": ["${workspaceFolder}/docs/case_examples/centered_circle"],
        },
    ]
}
```