import numpy as np
import pytest

from simulator.assembler import Assembler
from simulator.element import NodesHandler, Element, ElementsContainer
from simulator.element_enums import ElementType


def test_nodes_handler(nodes_handler):
    # TODO: remember to remove this transpose after change the fixture to import these
    assert nodes_handler.dimensions == 2
    assert nodes_handler.total_nodes == 2601
    nodes = nodes_handler.get_nodes_instances([0, 2600])
    assert np.allclose(nodes[0].position, np.array([0.0, 0.0]))
    assert np.allclose(nodes[1].position, np.array([1.0, 1.0]))
    nodes_handler.update_positions(
        np.ones((nodes_handler.total_nodes, nodes_handler.dimensions))
    )
    assert np.allclose(
        np.array(nodes_handler.get_positions(), dtype=np.float64),
        np.ones((nodes_handler.total_nodes, nodes_handler.dimensions)),
    )
    nodes_handler.update_positions(np.ones((2601, 2)))
    assert np.allclose(
        np.array(nodes_handler.get_positions(), dtype=np.float64),
        np.ones((2601, 2)),
    )
    # variables
    nodes_handler.update_variables("u_1", np.ones(2601))
    assert nodes_handler.get_variables("u_1")[200] == 1.0
    nodes_handler.update_variables_old("u_2", np.ones(2601))
    assert nodes_handler.get_variables_old("u_2")[200] == 1.0


def test_element(nodes_handler):
    element = Element(np.array([0, 52, 51], dtype=np.int32))
    nodes = element.get_nodes(nodes_handler)
    assert element.physical_group == 0 and element.geometrical_group == 0
    assert np.allclose(element.b, np.zeros(element.nodes_per_element))
    assert np.allclose(element.c, np.zeros(element.nodes_per_element))
    assert element.length == -1.0 and element.area == -1.0 and element.volume == -1.0
    assert element.dt == -1.0
    assert np.allclose(
        np.array([node.position for node in nodes]),
        np.array([[0.0, 0.0], [0.00334014, 0.00334014], [0.0, 0.00334014]]),
    )


def test_element_container(element_triangles):
    assert element_triangles.total_elements == 5000
    assert np.allclose(element_triangles.get_element(0).node_ids, np.array([0, 52, 51]))
    assert np.allclose(
        element_triangles.get_element(4999).node_ids, np.array([2548, 2549, 2600])
    )


# TODO: put here to do file regressions instead of assertions
def test_mesh_parameters(
    nodes_handler,
    element_triangles,
    modified_basic_matrix_set2,
    square_case_configs,
    shared_datadir,
):
    # calculate parameters for the mesh
    element_triangles.update_geometry_parameters(nodes_handler)
    assert np.allclose(
        [triangle.area for triangle in element_triangles.elements],
        modified_basic_matrix_set2["areas"],
    )
    element_triangles.update_shape_factors(nodes_handler)
    assert np.allclose(
        [triangle.b for triangle in element_triangles.elements],
        modified_basic_matrix_set2["b"],
    )
    assert np.allclose(
        [triangle.c for triangle in element_triangles.elements],
        modified_basic_matrix_set2["c"],
    )
    element_triangles.update_local_time_itervals(
        nodes_handler, square_case_configs["csafm"], square_case_configs["Re"]
    )
    dt = np.loadtxt(
        shared_datadir / "old_results" / "dt_clean" / "dt_00001.csv",
        delimiter=",",
    )
    assert np.allclose(
        [triangle.dt for triangle in element_triangles.elements],
        dt,
    )
