from enum import Enum, auto
import numpy as np
from numba import types, typed
from numba.experimental import jitclass
from typing import List


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


class ElementType(Enum):
    """All types of element supported for now"""

    NODE = auto()
    SEGMENT = auto()
    TRIANGLE = auto()
    QUADRILATERAL = auto()
    # TODO: complete this enum when implement other element types
    # ...


# Propriedade dos nos
# cinematica (posicao, velocidade, aceleracao)
# grupos (geometrico, fisico, named)
# variaveis (current, last)
# condicoes de contorno (tipo, variavel associada, grupo)


@jitclass(
    {
        "geometrical_group": types.int32,
        "physical_group": types.int32,
        "named_group": types.int32,
        "position": types.float64[:],
        "variables": types.DictType(keyty=types.unicode_type, valty=types.float64),
        "variables_old": types.DictType(keyty=types.unicode_type, valty=types.float64),
    }
)
class Node(object):
    """This class works as a struct to hold node data"""

    def __init__(self, position):
        # node groups
        self.geometrical_group = 0
        self.physical_group = 0
        self.named_group = 0
        # TODO: change this name to position, (include velocity and acceleration)
        self.position = position
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

    def __init__(self, dimensions, positions):
        self.dimensions = dimensions
        self.nodes = typed.List(
            [Node(position) for position in positions[:, :dimensions]]
        )

    @property
    def total_nodes(self):
        """The total amount of nodes"""
        return len(self.nodes)

    def get_nodes_instances(self, node_ids):
        """Return node instances with node_ids passed as argument"""
        return typed.List([self.nodes[node_id] for node_id in node_ids])

    def get_positions(self):
        """Return the positions of all nodes"""
        return typed.List(
            [self.nodes[node_id].position for node_id in range(self.total_nodes)]
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

    def set_group_numbers(self, group_type, group_numbers, node_ids):
        """
        Define group number for some nodes.
        The rule to define node groups is the current number of node is overridden
        only by a higher group number.
        """
        for group_number, node_id in zip(group_numbers, node_ids):
            match group_type:
                case GroupType.GEOMETRICAL.value:
                    if group_number > self.nodes[node_id].geometrical_group:
                        self.nodes[node_id].geometrical_group = group_number
                case GroupType.PHYSICAL.value:
                    if group_number > self.nodes[node_id].physical_group:
                        self.nodes[node_id].physical_group = group_number
                case GroupType.NAMED.value:
                    if group_number > self.nodes[node_id].named_group:
                        self.nodes[node_id].named_group = group_number

    def update_positions(self, new_positions):
        """Update position of all nodes in the mesh"""
        assert (
            self.total_nodes == new_positions.shape[0]
            and self.dimensions == new_positions.shape[1]
        )
        for node_id in range(self.total_nodes):
            self.nodes[node_id].position = new_positions[node_id, :]

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
        "named_group": types.int32,
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
    def __init__(self, node_ids):
        self.node_ids = node_ids
        self.physical_group = 0
        self.geometrical_group = 0
        self.named_group = 0
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

    def __init__(self, element_type, connectivity_matrix):
        self.element_type = element_type
        self.elements = typed.List(
            [Element(node_ids) for node_ids in connectivity_matrix]
        )

    @property
    def total_elements(self):
        """Get total amount of elements"""
        return len(self.elements)

    def get_element(self, element_id):
        """Return an element using id"""
        return self.elements[element_id]

    def set_group_numbers(self, group_type, group_numbers, nodes_handler):
        """
        Set the number of the groups for the elements and nodes in each element.
        The rule to define node groups is the current number of node is overridden
        only by a higher group number.
        """
        assert len(group_numbers) == self.total_elements
        # for element_id, group_number in enumerate(group_numbers):
        for element_id in range(self.total_elements):
            group_number = group_numbers[element_id]
            # set group number for nodes of this element
            node_ids = self.elements[element_id].node_ids
            nodes_group_numbers = np.full_like(node_ids, group_number)
            nodes_handler.set_group_numbers(group_type, nodes_group_numbers, node_ids)
            # set the group number for the element
            match group_type:
                case GroupType.GEOMETRICAL.value:
                    if group_number > self.elements[element_id].geometrical_group:
                        self.elements[element_id].geometrical_group = group_number
                case GroupType.PHYSICAL.value:
                    # set the group number for the element
                    if group_number > self.elements[element_id].physical_group:
                        self.elements[element_id].physical_group = group_number
                case GroupType.NAMED.value:
                    # set the group number for the element
                    if group_number > self.elements[element_id].named_group:
                        self.elements[element_id].named_group = group_number
