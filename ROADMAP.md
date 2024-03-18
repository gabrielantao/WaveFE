# ROADMAP
There are some features and improvements that could be implemented

# Features and improvements
1. implement one dimensional elements
2. implement two dimensional elements
3. implement higher order elements
4. implement mesh movement
5. review symmetric matrix assembling
6. implement mass matrix not lumped
7. review the equation formulations
8. implement three dimensional elements
9. general performance improvements
10. implement validations and input versioning
11. multiple mesh input formats
12. implement better debugging tools
13. implement group of elements
14. implement hybrid mesh
15. review elements specific properties
16. implement explicit method
17. implement artificial compressibility method
18. implement other domain conditions
19. implement model with heat transfer
20. implement model with chemical spiecies transfer
21. implement model with porous media 
22. add solvers and preconditioner options
23. automatically run validation tests cases
24. move application responsabilities to the Julia
25. add basic documentation
26. implement transient CBS 
27. add validation cases for the semi implicit
28. make the solver parallel
29. integrate to Paraview
30. preprocessing data for simulator
31. study and implement how to run not adimensional models
32. create benchmarks for the simulator


# Descriptions
## implement one dimensional elements
tags: mesh, modeling
complexity: 3/5
description:
requirements:
steps do get done:

## integrate to Paraview
tags: mesh, modeling
complexity: ?/5
description:
### requirements
it should:
 - call a simulation from paraview
 - visualize the result during the simulation or after that
 - generate/read events/log during the simulation and show in GUI interface 
### steps do get done:
- add output for the paraview format