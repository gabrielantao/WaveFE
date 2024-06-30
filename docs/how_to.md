# How to add new test cases

- create the folder of the case in `simulator/test/cases/my_test_case`;
- create the mesh file `my_mesh.msh` inside the folder;
- create the mesh file `simulation.toml` inside the folder. Remember to configure the name of the created mesh in this file;
- create the mesh file `conditions.toml` inside the folder, this can be done manually or you can use a script do make things easier if needed;
- add a test in the testcases list `simulator/test/cases/test_validation.jl`. Use the tests already added as example of how to do so. Remeber to register in the `ValidationCase` call the `my_test_case` as the folder of the test;
- run the test to make sure it generates the right result `pixi run test-case my_test_name`. If the test fails at first run you should try to use the current generated result (inside `simulator/test/cases/my_test_case/cache/result`) running the test adding the flag to regenerate the referente result i.e. you can run `pixi run test-case my_test_name -r`;
- then commit and push the result to the repository.


# tips for debug
- check if everything is ok with the mesh, open it somewhere you can visualize or run something that can check the mesh integrity