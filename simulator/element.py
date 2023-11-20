from enum import Enum, auto
import numpy as np
from numba import types, typed
from numba.experimental import jitclass
from typing import List


# TODO: complete this class when implement other element types
class ElementType(Enum):
    """All types of element supported for now"""

    NODE = auto()
    SEGMENT = auto()
    TRIANGLE = auto()
    QUADRILATERAL = auto()
    # ...


@jitclass(
    {
        "coordinates": types.float64[:, :],
        "variables": types.DictType(keyty=types.unicode_type, valty=types.float64[:]),
        "variables_old": types.DictType(
            keyty=types.unicode_type, valty=types.float64[:]
        ),
    }
)
class NodesHandler(object):
    """
    A class that holds data for all nodes such as coordinates and variables values.
    """

    # TODO: maybe add group data for nodes ...
    def __init__(self, dimension, coordinate_matrix):
        self.coordinates = coordinate_matrix[:, :dimension]
        # it maps the name of the variable to number of the column it belongs to
        self.variables = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64[:]
        )
        self.variables_old = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64[:]
        )

    @property
    def dimensions(self):
        """The nodes dimension"""
        return self.coordinates.shape[1]

    @property
    def total_nodes(self):
        """The total amount of nodes"""
        return self.coordinates.shape[0]

    def get_coordinate(self, node_id):
        """Return the coordinates given a node id"""
        return self.coordinates[node_id, :]

    def get_node_variable(self, variable_name, node_id):
        """Return the variables values given a node id"""
        return self.variables[variable_name][node_id]

    def get_node_variable_old(self, variable_name, node_id):
        """Return the variables old values given a node id"""
        return self.variables_old[variable_name][node_id]

    def update_all_coordinates(self, new_coordinates):
        """Update coordinate of all nodes in the mesh"""
        assert self.coordinates.shape == new_coordinates.shape
        self.coordinates = new_coordinates

    def update_coordinate(self, node_id, new_coordinate):
        """Update coordinates for node_ids passed values"""
        self.coordinates[node_id, :] = new_coordinate[:]

    def update_variables(self, variable_name, new_values):
        """Update the values of a variables for all nodes"""
        self.variables[variable_name] = new_values

    def update_variables_old(self, variable_name, new_values):
        """Update the values of a variables_old for all nodes"""
        self.variables_old[variable_name] = new_values


@jitclass(
    {
        "node_ids": types.int32[:],
        "physical_group": types.int32,
        "geometrical_group": types.int32,
        "b": types.float64[:],
        "c": types.float64[:],
        "length": types.float64,
        "area": types.float64,
        "volume": types.float64,
        "dt": types.float64,
    }
)
class Element(object):
    """A class for all elements types"""

    # TODO: maybe add parameters (e.g. Re, Ra, etc.) as a dict of floats here...
    def __init__(self, node_ids, physical_group, geometrical_group):
        self.node_ids = node_ids
        self.physical_group = physical_group
        self.geometrical_group = geometrical_group
        # derivative coefficients b, c
        self.b = np.zeros(self.node_ids.shape, dtype=np.float64)
        self.c = np.zeros(self.node_ids.shape, dtype=np.float64)
        self.length = -1.0
        self.area = -1.0
        self.volume = -1.0
        self.dt = -1.0

    @property
    def nodes_per_element(self):
        """The amount of nodes for this element"""
        return self.node_ids.shape[0]

    def get_coordinates(self, nodes):
        """Get all nodes coordinates that belongs to this element"""
        return nodes.get_coordinate(self.node_ids)

    def get_variables(self, nodes):
        """Get all variables values for nodes that belongs to this element"""
        variables = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64[:]
        )
        for name in nodes.variables.keys():
            variables[name] = nodes.get_node_variable(name, self.node_ids)
        return variables

    def get_variables_old(self, nodes):
        """Get all last variables values for nodes that belongs to this element"""
        variables = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64[:]
        )
        for name in nodes.variables_old.keys():
            variables[name] = nodes.get_node_variable_old(name, self.node_ids)
        return variables

    # TODO: implement these functions
    # calculate_specific_sizes (maybe save this in memory)
    # update_local_time_interval
    # update_area
    # update_shape_factors
    # TODO: maybe implement these functions
    # update_properties
    # get_edges_ids


@jitclass()
class ElementsContainer(object):
    """
    A container class to hold a group of elements of a same type.
    A instance of this class should be created for each type of elements in mesh
    """

    element_type: int
    elements: List[Element]

    def __init__(
        self, element_type, connectivity_matrix, physical_groups, geometrical_groups
    ):
        self.element_type = element_type
        self.elements = typed.List(
            [
                Element(node_ids, physical_group, geometrical_group)
                for node_ids, physical_group, geometrical_group in zip(
                    connectivity_matrix, physical_groups, geometrical_groups
                )
            ]
        )

    @property
    def total_elements(self):
        """Get total amount of elements"""
        return len(self.elements)

    def get_element(self, element_id):
        """Return an element using id"""
        return self.elements[element_id]
