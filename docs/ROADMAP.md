# ROADMAP
There are some features and improvements that could be implemented

# Mesh and elements features 

## implement segment elements
### general information
- tags: `mesh`, `element`, `assembling`
- complexity: 2/5
- description: implement the unidimensional element called "segment". 
- dependency: -

### TODO list
- add length calculation function
- implement functions to update element property
- implement the assembling elemental function for the models for all equations
- add unit tests to read example mesh 
- add unit tests for all new the functions
- create at least a case with a mesh containing this element
- add a validation for the created case


## implement quadrilateral elements
## general information
- tags: `mesh`, `element`, `assembling` 
- complexity: 3/5
- description: implement the bidimensional element called "quadrialteral".
- dependency: -

### TODO list
- add area calculation function
- implement functions to update element property
- implement the assembling elemental function for the models for all equations
- add unit tests to read example mesh 
- add unit tests for all new the functions
- create at least a case with a mesh containing this element 
- add a validation for the created case


## implement hybrid bidimensional mesh
### general information
- tags: `mesh`
- complexity: 3/5
- description: implement example of case using the bidimensional elements in the mesh.
- dependency: `implement quadrilateral elements`

### TODO list
- add unit tests to read hybrid mesh 
- create at least a case with a mesh containing quadrilaterals and triangles
- add a validation for the created case


## implement higher order bidimensional elements
### general information
- tags: `element`, `assembling` 
- complexity: 3/5
- description: implement elements with higher order elements interpolations.
- dependency: -

### TODO list
- add unit tests to check matrices with higher order elements
- create at least a case with a mesh containing higher order elements for available elements
- add a validation for the created case
NOTE: the package [JuliaFEM](https://github.com/JuliaFEM/JuliaFEM.jl) could be useful here

## implement three dimensional elements
### general information
- tags: `mesh`, `element`, `assembling`
- complexity: 3/5
- description: implement the tridimensional elements such as tetrahedron and hexahedron.
- dependency: -

### TODO list
- add volume calculation function
- implement functions to update element property
- implement the assembling elemental function for the models for all equations
- add unit tests to read example mesh 
- add unit tests for all new the functions
- create at least a case with a mesh containing the new elements
- add a validation case for the new element


## multiple mesh input formats
### general information
- tags: `mesh`
- complexity: 2/5
- description: allow import other formats of mesh.
- dependency: -

### TODO list
- search for a package Julia that allows to import multiple formats for the mesh or to convert other mesh formats to gmsh then import it
- create the unit tests to ensure everything is working
NOTE: a package that can be useful here is [MeshIO.jl](https://github.com/JuliaIO/MeshIO.jl)


## implement group of elements
TODO: this task must be reviews if it is really needed
### general information
- tags: `mesh`
- complexity: 2/5
- description: create group as elements. groups of elements could be useful to define some properties for the elements.
- dependency: -

### TODO list
- add the groups where is defined in the code
- create tests with mesh importing data defined for the groups 


## review elements specific properties
TODO: this task must be reviews if it is really needed
### general information
- tags: `mesh`
- complexity: 2/5
- description: create group as elements. using groups of elements it could be useful to define the properties for the elements.
- dependency: -

### TODO list
- add the properties for the groups where is defined in the code
- create tests with mesh importing data defined for the groups 


# Debugging and view results pre- and posprocessing
## implement better debugging tools
### general information
- tags: `improvements`
- complexity: 2/5
- description: several minor improvements for better developer experience
- dependency: -

### TODO list
- check where in the code are labeled with this task name and implement what is in the comments

## implement validations and input versioning
### general information
- tags: `improvements`
- complexity: 2/5
- description: implement the use of version of input files to check if input is valid by versioning the input expected data
- dependency: -

### TODO list
- check where in the code are labeled with this task name and implement what is in the comments

## new i/o format for the results
### general information
- tags: `posprocessing`, `integration`, `mesh`, `output`
- complexity: 2/5
- description: add ability to import and export inputs and results in other formats
- dependency: -

### TODO list
- think if in this task the handmade Gmsh file import should be replaced by `FiniteMesh` package
- convert the default output hdf5 to generate the input/output as CGNS
- generate the output for the Paraview as VTK file
- add tests to input/output the data of a simulation
NOTE: a package that can be useful here is [WriteVTK](https://github.com/JuliaVTK/WriteVTK.jl) 
NOTE: a package that can be useful here is [FiniteMesh](https://github.com/vavrines/FiniteMesh.jl)


## integrate to Paraview
### general information
- tags: `posprocessing`, `integration`
- complexity: 4/5
- description: call a simulation from Paraview and see results from there
- dependency: `new output format for the results`

### TODO list
- integrate the WaveFE to call a simulation from Paraview
- generate/read events/log during the simulation and show in GUI interface 
- implement visualize the result during the simulation or after


# List of additional features and improvements
For these improvements contact the owner of repository or create an issue.

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
- implement how to run not adimensional models

## CBS new models
- implement other domain conditions
- implement model with heat transfer
- implement model with chemical species transfer
- implement model with porous media 