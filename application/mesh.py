from pathlib import Path
import logging
import re
import numpy as np
import meshio
from enum import Enum, StrEnum, auto


class GroupType(Enum):
    """
    Enum to hold data for type of the group
    physical and geometrical groups are free to use inside the model
    (e.g. to define boundary to calculate some properties such as drag and lift in surface)
    named group is used to define boundary conditions
    """

    GEOMETRICAL = auto()
    PHYSICAL = auto()
    NAMED = auto()


class ElementType(StrEnum):
    """All types of element supported for now"""

    NODE = "node"
    SEGMENT = "segments"
    TRIANGLE = "triangles"
    QUADRILATERAL = "quadrilaterals"
    # TODO [implement three dimensional elements]
    ## complete this enum when implement other element types


class NodesHandler:
    def __init__(self, dimension, positions):
        self.total_nodes = positions.shape[0]
        self.positions = positions[:, 0:dimension]
        # TODO [implement mesh movement]
        ## implement here a way to inform the initial velocities and accelerations
        self.velocities = np.zeros_like(self.positions)
        self.accelerations = np.zeros_like(self.positions)
        self.geometrical_group = np.zeros(self.total_nodes, dtype=np.int64)
        self.physical_group = np.zeros(self.total_nodes, dtype=np.int64)
        self.domain_condition_groups = np.zeros(self.total_nodes, dtype=np.int64)

    def set_group_numbers(self, group_type, group_numbers, node_ids):
        """
        Define group number for some nodes.
        The rule to define node groups is the current number of node is overridden
        only by a higher group number.
        """
        for group_number, node_id in zip(group_numbers, node_ids):
            match group_type:
                case GroupType.GEOMETRICAL.value:
                    if group_number > self.geometrical_group[node_id]:
                        self.geometrical_group[node_id] = group_number
                case GroupType.PHYSICAL.value:
                    if group_number > self.physical_group[node_id]:
                        self.physical_group[node_id] = group_number
                case GroupType.NAMED.value:
                    if group_number > self.domain_condition_groups[node_id]:
                        self.domain_condition_groups[node_id] = group_number


class ElementsContainer:
    def __init__(self, element_type, connectivity_matrix):
        self.element_type = element_type
        self.total_elements = connectivity_matrix.shape[0]
        self.connectivity = connectivity_matrix

        # TODO [implement group of elements]
        ## for now these groups are not used but they can be useful to set properties for elements
        self.geometrical_group = np.zeros(self.total_elements, dtype=np.int64)
        self.physical_group = np.zeros(self.total_elements, dtype=np.int64)
        self.domain_condition_groups = np.zeros(self.total_elements, dtype=np.int64)

    def set_group_numbers(self, group_type, group_numbers, nodes_handler):
        """
        Set the number of the groups for the elements and nodes in each element.
        The rule to define node groups is the current number of node is overridden
        only by a higher group number.
        """
        assert len(group_numbers) == self.total_elements

        for element_id in range(self.total_elements):
            group_number = group_numbers[element_id]
            # TODO [implement group of elements]
            ##  check if it should reset the groups for the nodes
            ## set group number for nodes of this element
            ## node_ids = self.elements[element_id].node_ids
            ## nodes_group_numbers = np.full_like(node_ids, group_number)
            ## nodes_handler.set_group_numbers(group_type, nodes_group_numbers, node_ids)

            # set the group number for the element
            match group_type:
                case GroupType.GEOMETRICAL.value:
                    if group_number > self.geometrical_group[element_id]:
                        self.geometrical_group[element_id] = group_number
                case GroupType.PHYSICAL.value:
                    # set the group number for the element
                    if group_number > self.physical_group[element_id]:
                        self.physical_group[element_id] = group_number
                case GroupType.NAMED.value:
                    # set the group number for the element
                    if group_number > self.domain_condition_groups[element_id]:
                        self.domain_condition_groups[element_id] = group_number


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
    ELEMENT_GROUP_TRANSLATION = {
        "gmsh:geometrical": GroupType.GEOMETRICAL.value,
        "gmsh:physical": GroupType.PHYSICAL.value,
    }

    # TODO: maybe this class should run a integrity check for the mesh
    def __init__(self, mesh_filepath: Path, interpolation_order: int = 1):
        self.filepath = mesh_filepath
        self.interpolation_order = interpolation_order
        # setup mesh data to internal classes
        mesh = meshio.read(mesh_filepath)
        self.setup_nodes(mesh)
        self.setup_elements(mesh)
        self.setup_groups(mesh)
        self.setup_domain_condition_groups(mesh)

    def setup_nodes(self, mesh):
        """Create nodes handler with nodes from mesh file"""
        # infer dimension of a mesh by checking zeros in points positions
        all_zero_dim_2 = all(np.isclose(mesh.points[:, 1], 0.0))
        all_zero_dim_3 = all(np.isclose(mesh.points[:, 2], 0.0))
        if all_zero_dim_2 and all_zero_dim_3:
            self.dimension = 1
        elif all_zero_dim_3:
            self.dimension = 2
        else:
            self.dimension = 3
        self.nodes_handler = NodesHandler(dimension, mesh.points)

    def setup_elements(self, mesh):
        """Create element containers and configure it with data from mesh file"""
        self.element_containers = {}
        # get total number of elements and groups for a given group type and element type
        for element_name, connectivity in mesh.cells_dict.items():
            element_type = self._get_element_type(element_name)
            # ignore nodes in the element connectivity
            if element_type == ElementType.NODE.value:
                continue
            # TODO [multiple mesh input formats]
            ## check if it works for other imported formats (prefix 'gmsh' can break)
            self.element_containers[element_type] = ElementsContainer(
                element_type,
                connectivity,
            )

    def setup_groups(self, mesh):
        """
        Configure node and element physical and geometrical groups.
        These groups can be used for example to easly setup nodes movements or
        to calcualte properties in some some surface (e.g. drag/lift forces).
        Both element and nodes could be in marked in named groups.
        """
        # TODO [implement better debugging tools]
        ## this function should log each pass of the group setter to debug propurses
        ## this can be done saving all nodes and element groups in a pandas dataframe

        # setup geometrical and physical group numbers for elements and nodes
        for group_name, elements_groups in mesh.cell_data_dict.items():
            group_type = self._get_element_group_type(group_name)
            for element_name, group_numbers in elements_groups.items():
                element_type = self._get_element_type(element_name)
                # define directly group of nodes explicitly defined as
                # geometrical/physical groups in the mesh file
                if element_type == ElementType.NODE.value:
                    node_ids = mesh.cells_dict[element_name].flatten()
                    self.nodes_handler.set_group_numbers(
                        group_type, group_numbers, node_ids
                    )
                else:
                    self.element_containers[element_type].set_group_numbers(
                        group_type, group_numbers, self.nodes_handler
                    )

    def setup_domain_condition_groups(self, mesh):
        """
        Configure node and element named groups.
        These groups can be used for example to easly setup boundary conditions.
        Both element and nodes could be in marked in named groups.
        """
        # TODO [implement better debugging tools]
        ## this function should log each pass of the group setter to debug propurses
        ## this can be done saving all nodes and element groups in a pandas dataframe

        # setup named groups
        self.domain_condition_groups = {
            group_name: number[0] for group_name, number in mesh.field_data.items()
        }
        for group_name, elements_groups in mesh.cell_sets_dict.items():
            # ignore groups that were not named by user that created the mesh
            if re.match("gmsh:*", group_name):
                # TODO [multiple mesh input formats]
                ## check how this behaves for other input mesh formats
                ## maybe meshio can put other prefix for other formats...
                continue
            # the named elements comes with indices instead of an array with all group numbers
            # so the trick here is just create an array full of zeros and use the indices to
            # fill the group number only where needed
            for element_name, indices in elements_groups.items():
                element_type = self._get_element_type(element_name)
                # define directly group of nodes explicitly defined as
                # geometrical/physical groups in the mesh file
                if element_type == ElementType.NODE.value:
                    group_numbers = np.full_like(
                        indices,
                        self.domain_condition_groups[group_name],
                        dtype=np.int64,
                    )
                    self.nodes_handler.set_group_numbers(
                        GroupType.NAMED.value, group_numbers, indices
                    )
                else:
                    group_numbers = np.zeros(
                        self.element_containers[element_type].total_elements,
                        dtype=np.int64,
                    )
                    group_numbers[indices] = self.domain_condition_groups[group_name]
                    self.element_containers[element_type].set_group_numbers(
                        GroupType.NAMED.value,
                        group_numbers,
                        self.nodes_handler,
                    )

    def _get_element_type(self, element_name: str):
        """
        Translate the name of element that comes from imported mesh into the internal element number (see ElementType)
        """
        if element_name in self.ELEMENT_NAME_TRANSLATION:
            return self.ELEMENT_NAME_TRANSLATION[element_name]
        raise RuntimeError(f"Element named {element_name} not implemented yet.")

    def _get_element_group_type(self, group_name: str) -> None:
        """
        Translate the name of group of element that comes from imported mesh into the internal element number (see GroupType)
        """
        if group_name in self.ELEMENT_GROUP_TRANSLATION:
            return self.ELEMENT_GROUP_TRANSLATION[group_name]
        raise RuntimeError(f"Element group named {group_name} not implemented.")

    def get_element_containers(self):
        """Return element container to be used in assembling depending on mesh dimension"""
        element_types = []
        match self.nodes_handler.dimensions:
            case 1:
                # TODO [implement one dimensional elements]
                raise NotImplementedError("Not implement 1D meshs yet")
            case 2:
                element_types.append(ElementType.TRIANGLE.value)
                element_types.append(ElementType.QUADRILATERAL.value)
            case 3:
                # TODO [implement three dimensional elements]
                raise NotImplementedError("Not implement 3D meshs yet")
        used_containers = []
        for element_type in element_types:
            if element_type in self.element_containers:
                used_containers.append(self.element_containers[element_type])
        return used_containers
