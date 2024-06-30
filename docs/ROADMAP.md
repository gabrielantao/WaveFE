# ROADMAP
There are some features and improvements that could be implemented

# List of features and improvements
## Mesh and elements features 
- implement segment elements
- implement quadrilateral elements
- implement hybrid bidimensional mesh
- implement higher order elements
- implement three dimensional elements
- multiple mesh input formats
- implement group of elements
- review elements specific properties
- implement subgroups of Gmsh physical groups

## Performance improvements for solver/assembler
- add solvers and preconditioner options
- review symmetric matrix assembling
- general performance improvements
- make the solver parallel
- create benchmarks for the simulator

## CBS methods
- implement mass matrix not lumped
- implement transient CBS 
- review the equation formulations
- implement mesh movement
- implement explicit method
- implement artificial compressibility method
- study and implement how to run not adimensional models

## Debugging and view results pre- and posprocessing
- implement better debugging tools
- implement validations and input versioning
- new i/o format for the results
- integrate to Paraview

## CBS new models
- implement other domain conditions
- implement model with heat transfer
- implement model with chemical species transfer
- implement model with porous media 


# implement segment elements
TODO: change in the source the `implement one dimensional elements` by this name

## general information
- tags: `mesh`, `element`, `assembling`
- complexity: 2/5
- description: implement the unidimensional element called "segment". 
- dependency: -

## TODO list
- add length calculation function
- implement functions to update element property
- implement the assembling elemental function for the models for all equations
- add unit tests to read example mesh 
- add unit tests for all new the functions
- create at least a case with a mesh containing this element
- add a validation for the created case


# implement quadrilateral elements
TODO: change in the source the `implement two dimensional elements` by this name

## general information
- tags: `mesh`, `element`, `assembling` 
- complexity: 3/5
- description: implement the bidimensional element called "quadrialteral".
- dependency: -

## TODO list
- add area calculation function
- implement functions to update element property
- implement the assembling elemental function for the models for all equations
- add unit tests to read example mesh 
- add unit tests for all new the functions
- create at least a case with a mesh containing this element 
- add a validation for the created case


# implement hybrid bidimensional mesh
TODO: change in the source the `implement hybrid mesh` by this name

## general information
- tags: `mesh`
- complexity: 3/5
- description: immplement example of case using the bidimensional elements in the mesh.
- dependency: `implement quadrilateral elements`

## TODO list
- add unit tests to read hybrid mesh 
- create at least a case with a mesh containing quadrilaterals and triangles
- add a validation for the created case


# new i/o format for the results
## general information
- tags: `posprocessing`, `integration`, `mesh`, `output`
- complexity: 2/5
- description: add ability to import and export inputs and results in other formats
- dependency: -

## TODO list
- think if in this task the handmade Gmsh file import should be replaced by `FiniteMesh` package
- convert the default output hdf5 to generate the input/output as CGNS
- generate the output for the Paraview as VTK file
- add tests to input/output the data of a simulation
NOTE: a package that can be useful here is [WriteVTK](https://github.com/JuliaVTK/WriteVTK.jl) 
NOTE: a package that can be useful here is [FiniteMesh](https://github.com/vavrines/FiniteMesh.jl)

# integrate to Paraview
## general information
- tags: `posprocessing`, `integration`
- complexity: 4/5
- description: call a simulation from Paraview and see results from there
- dependency: `new output format for the results`

## TODO list
- integrate the WaveFE to call a simulation from Paraview
- generate/read events/log during the simulation and show in GUI interface 
- implement visualize the result during the simulation or after
