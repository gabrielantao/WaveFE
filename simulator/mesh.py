from pathlib import Path
import logging
import numpy as np
import meshio

from simulator.element import ElementType, NodesHandler, ElementsContainer


class Mesh:
    """
    This class import mesh data. Any mesh suported by meshio can be imported.
    e.g. the user can use a gmsh script to generate a mesh file "my_mesh.msh".
    Other approachs can be used to generate a mesh such as:
    - use package [MeshPy](https://pypi.org/project/MeshPy/)
    - use [gmsh script system](https://gmsh.info/doc/texinfo/gmsh.html#Gmsh-tutorial)
    - use package [pymesh](https://pypi.org/project/pygmsh/)
    - etc.

    Then call write_simulation_files
    3) the Wave mesh (internal format) files are generated with physical values
    (e.g. initial conditions, boundary conditions) are attached and cached.
    The file checksums are created and if they are changed the mesh is regenerated
    """

    ELEMENT_NAME_TRANSLATION = {
        "vertex": ElementType.NODE.value,
        "line": ElementType.SEGMENT.value,
        "triangle": ElementType.TRIANGLE.value,
    }

    # TODO: maybe this class should run a integrity check for the mesh
    def __init__(self, mesh_filepath: Path, interpolation_order: int = 1):
        self.filepath = mesh_filepath
        self.interpolation_order = interpolation_order
        # setup mesh data to internal classes
        mesh = meshio.read(mesh_filepath)
        self.setup_nodes(mesh)
        self.setup_elements(mesh)
        # named groups are used by boundary conditions handler
        self.setup_named_groups(mesh)

    def setup_nodes(self, mesh):
        """Create nodes handler with nodes from mesh file"""
        # infer dimension of a mesh by checking zeros in points coordinates
        all_zero_dim_2 = all(np.isclose(mesh.points[:, 1], 0.0))
        all_zero_dim_3 = all(np.isclose(mesh.points[:, 2], 0.0))
        if all_zero_dim_2 and all_zero_dim_3:
            self.nodes = NodesHandler(1, mesh.points)
        elif all_zero_dim_3:
            self.nodes = NodesHandler(2, mesh.points)
        else:
            self.nodes = NodesHandler(3, mesh.points)

    def setup_elements(self, mesh):
        """Create element containers and configure it with data from mesh file"""
        self.element_containers = {}
        # get total number of elements and groups for a given group type and element type
        for element_name, connectivity in mesh.cells_dict.items():
            element_type = self.get_element_type(element_name)
            # ignore nodes in the element connectivity
            if element_type == ElementType.NODE.value:
                continue
            # TODO: check if it works for other imported formats (prefix 'gmsh' can break)
            self.element_containers[element_type] = ElementsContainer(
                element_type,
                connectivity.astype(np.int32),
                mesh.cell_data_dict["gmsh:physical"][element_name],
                mesh.cell_data_dict["gmsh:geometrical"][element_name],
            )

    def setup_named_groups(self, mesh):
        """Configure named groups. These groups are used to easly setup boundary conditions"""
        self.named_groups = {}
        for group_name, elements in mesh.cell_sets_dict.items():
            self.named_groups[group_name] = {
                self.get_element_type(element_name): element_indices
                for element_name, element_indices in elements.items()
            }

    def get_element_type(self, element_name: str):
        """
        Translate the name of element that comes from imported mesh into the internal element number (see ElementType)
        """
        if element_name in self.ELEMENT_NAME_TRANSLATION:
            return self.ELEMENT_NAME_TRANSLATION[element_name]
        raise RuntimeError(f"Element named {element_name} not implemented yet.")

    def get_element_containers(self) -> list[ElementsContainer]:
        """Return element container to be used in assembling depending on mesh dimension"""
        element_types = []
        match self.nodes.dimensions:
            case 1:
                element_types.append(ElementType.SEGMENT.value)
            case 2:
                element_types.append(ElementType.TRIANGLE.value)
                element_types.append(ElementType.QUADRILATERAL.value)
            case 3:
                raise NotImplementedError("Not implement 3D meshs yet")
        return [self.element_containers[element_type] for element_type in element_types]
