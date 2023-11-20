# modulo com codigo modificado fortran
import numpy as np
import pytest

from simulator.assembler import Assembler
from simulator.element import NodesHandler, Element, ElementsContainer, ElementType


def test_nodes_handler(nodes_handler):
    # TODO: remember to remove this transpose after change the fixture to import these
    assert nodes_handler.dimensions == 2
    assert nodes_handler.total_nodes == 2601
    assert np.allclose(nodes_handler.get_coordinate(0), np.array([0.0, 0.0]))
    assert np.allclose(nodes_handler.get_coordinate(2600), np.array([1.0, 1.0]))
    nodes_handler.update_all_coordinates(
        np.ones((nodes_handler.total_nodes, nodes_handler.dimensions))
    )
    assert np.allclose(
        nodes_handler.coordinates,
        np.ones((nodes_handler.total_nodes, nodes_handler.dimensions)),
    )
    nodes_handler.update_coordinate(2, np.array([2.0, 4.0]))
    assert np.allclose(nodes_handler.get_coordinate(2), np.array([2.0, 4.0]))
    nodes_handler.update_all_coordinates(np.ones((2601, 2)))
    assert np.allclose(nodes_handler.coordinates, np.ones((2601, 2)))
    # variables
    nodes_handler.update_variables("u_1", np.ones(2601))
    assert nodes_handler.get_node_variable("u_1", 200) == 1.0
    nodes_handler.update_variables_old("u_2", np.ones(2601))
    assert nodes_handler.get_node_variable_old("u_2", 200) == 1.0


def test_element(nodes_handler):
    element = Element(np.array([0, 52, 51], dtype=np.int32), 0, 0)
    assert element.nodes_per_element == 3
    assert np.allclose(
        element.get_coordinates(nodes_handler),
        np.array([[0.0, 0.0], [0.00334014, 0.00334014], [0.0, 0.00334014]]),
    )
    # check variables
    variables = element.get_variables(nodes_handler)
    assert list(variables.keys()) == ["u_1", "u_2", "p"]
    for variables_values in variables.values():
        assert np.allclose(variables_values, np.zeros(3))
    variables_old = element.get_variables_old(nodes_handler)
    assert list(variables_old.keys()) == ["u_1", "u_2", "p"]
    for variables_values in variables_old.values():
        assert np.allclose(variables_values, np.zeros(3))


def test_element_container(connectivity_matrix):
    container = ElementsContainer(
        ElementType.TRIANGLE.value,
        connectivity_matrix - 1,
        np.zeros(5000),
        np.zeros(5000),
    )
    assert container.total_elements == 5000
    assert np.allclose(container.get_element(0).node_ids, np.array([0, 52, 51]))
    assert np.allclose(
        container.get_element(4999).node_ids, np.array([2548, 2549, 2600])
    )
