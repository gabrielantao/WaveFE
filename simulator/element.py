from enum import Enum, auto
import numpy as np
from numba import types, typed
from numba.experimental import jitclass
from typing import List


class ElementType(Enum):
    """All types of element supported for now"""

    NODE = auto()
    SEGMENT = auto()
    TRIANGLE = auto()
    QUADRILATERAL = auto()
    # TODO: complete this class when implement other element types
    # ...


@jitclass(
    {
        "physical_group": types.int32,
        "geometrical_group": types.int32,
        "coordinates": types.float64[:],
        "variables": types.DictType(keyty=types.unicode_type, valty=types.float64),
        "variables_old": types.DictType(keyty=types.unicode_type, valty=types.float64),
    }
)
class Node(object):
    """This class works as a struct to hold node data"""

    def __init__(self, physical_group, geometrical_group, coordinates):
        self.physical_group = physical_group
        self.geometrical_group = geometrical_group
        self.coordinates = coordinates
        # it maps the name of the variable to number of the column it belongs to
        self.variables = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64
        )
        self.variables_old = typed.Dict.empty(
            key_type=types.unicode_type, value_type=types.float64
        )


@jitclass()
class NodesHandler(object):
    """A class that holds and manages nodes instances"""

    dimensions: int
    nodes: List[Node]

    def __init__(self, dimensions, coordinate_matrix):
        self.dimensions = dimensions
        # TODO: insert geometrical and physical groups for this
        self.nodes = typed.List(
            [
                Node(0, 0, coordinates)
                for coordinates in coordinate_matrix[:, :dimensions]
            ]
        )

    @property
    def total_nodes(self):
        """The total amount of nodes"""
        return len(self.nodes)

    def get_nodes_instances(self, node_ids):
        """Return node instances with node_ids passed as argument"""
        return typed.List([self.nodes[node_id] for node_id in node_ids])

    def get_coordinates(self):
        """Return the coordinates of all nodes"""
        return typed.List(
            [self.nodes[node_id].coordinates for node_id in range(self.total_nodes)]
        )

    def get_variables(self, variable_name):
        """Return the variables values for all nodes"""
        return typed.List(
            [
                self.nodes[node_id].variables[variable_name]
                for node_id in range(self.total_nodes)
            ]
        )

    def get_variables_old(self, variable_name):
        """Return the variables old values given a node id"""
        return typed.List(
            [
                self.nodes[node_id].variables_old[variable_name]
                for node_id in range(self.total_nodes)
            ]
        )

    def update_coordinates(self, new_coordinates):
        """Update coordinate of all nodes in the mesh"""
        assert (
            self.total_nodes == new_coordinates.shape[0]
            and self.dimensions == new_coordinates.shape[1]
        )
        for node_id in range(self.total_nodes):
            self.nodes[node_id].coordinates = new_coordinates[node_id, :]

    def update_variables(self, variable_name, new_values):
        """Update the values of a variables for all nodes"""
        for node_id in range(self.total_nodes):
            self.nodes[node_id].variables[variable_name] = new_values[node_id]

    def update_variables_old(self, variable_name, new_values):
        """Update the values of a variables_old for all nodes"""
        for node_id in range(self.total_nodes):
            self.nodes[node_id].variables_old[variable_name] = new_values[node_id]


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
        # local timestep for CBS model
        self.dt = -1.0

    @property
    def nodes_per_element(self):
        """The amount of nodes for this element"""
        return self.node_ids.shape[0]

    def get_nodes(self, nodes):
        """Return a list of instance of nodes to be used"""
        return nodes.get_nodes_instances(self.node_ids)

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
