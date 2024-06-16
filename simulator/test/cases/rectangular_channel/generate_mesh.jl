# Mesh generator for the rectangular mesh
import gmsh

# Before using any functions in the Julia API, Gmsh must be initialized:
gmsh.initialize()
gmsh.model.add("rectangular_channel")

# Remember that by default, if physical groups are defined, Gmsh will export in
# the output mesh file only those elements that belong to at least one physical
# group. To force Gmsh to save all elements, you can use
gmsh.option.setNumber("Mesh.SaveAll", 1)


# boundary points
gmsh.model.geo.addPoint(0.0, 0.0, 0.0, 0.105, 1)
gmsh.model.geo.addPoint(15.0, 0.0, 0.0, 0.105, 2)
gmsh.model.geo.addPoint(15.0, 1.0, 0.0, 0.105, 3)
gmsh.model.geo.addPoint(0.0, 1.0, 0.0, 0.105, 4)


# add countour lines
gmsh.model.geo.addLine(1, 2)
gmsh.model.geo.addLine(2, 3)
gmsh.model.geo.addLine(3, 4)
gmsh.model.geo.addLine(4, 1)

# add curve and the plane
gmsh.model.geo.addCurveLoop([1, 2, 3, 4], 1)
gmsh.model.geo.addPlaneSurface([1], 1)
gmsh.model.geo.synchronize()

# add group upper and lower walls
gmsh.model.addPhysicalGroup(1, [4], -1, "inlet")
gmsh.model.addPhysicalGroup(1, [2], -1, "outlet")
gmsh.model.addPhysicalGroup(1, [1, 3], -1, "no-slip")

gmsh.model.mesh.generate(2)
gmsh.write("rectangular_channel.msh")


# if !("-nopopup" in ARGS)
#     gmsh.fltk.run()
# end

gmsh.finalize()
