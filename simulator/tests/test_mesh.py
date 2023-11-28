import numpy as np
from pytest_regressions.num_regression import NumericRegressionFixture
from simulator.mesh import Mesh
from simulator.element import ElementType


# TODO: implement tests for import the different mesh input formats


def test_import_mesh(shared_datadir):
    mesh = Mesh(shared_datadir / "mesh.msh")
    # check nodes stuff
    assert mesh.nodes_handler.dimensions == 2
    assert mesh.nodes_handler.total_nodes == 2129
    assert np.all(len(node.variables) == 0 for node in mesh.nodes_handler.nodes)
    assert np.all(len(node.variables_old) == 0 for node in mesh.nodes_handler.nodes)
    # check elements stuff
    assert len(mesh.element_containers) == 2
    assert (
        ElementType.SEGMENT.value in mesh.element_containers
        and ElementType.TRIANGLE.value in mesh.element_containers
    )
    assert len(mesh.element_containers[ElementType.SEGMENT.value].elements) == 168
    assert len(mesh.element_containers[ElementType.TRIANGLE.value].elements) == 4088


def test_mesh_groups(shared_datadir, num_regression):
    mesh = Mesh(shared_datadir / "mesh.msh")
    # convert numpy into lists to do the regression
    # TODO: dar regression aqui dos nodos dos 3 tipos
    geometrical_group = []
    physical_group = []
    named_group = []
    for node in mesh.nodes_handler.nodes:
        geometrical_group.append(node.geometrical_group)
        physical_group.append(node.physical_group)
        named_group.append(node.named_group)
        if np.allclose(node.coordinates, np.array([0.0, 0.0])):
            assert node.named_group == 4
        elif np.allclose(node.coordinates, np.array([0.0, 1.0])):
            assert node.named_group == 3
        elif np.allclose(node.coordinates, np.array([1.0, 0.0])):
            assert node.named_group == 3
        elif np.allclose(node.coordinates, np.array([1.0, 1.0])):
            assert node.named_group == 3
        else:
            if np.isclose(node.coordinates[1], 1.0):
                assert node.named_group == 2
            if np.isclose(node.coordinates[1], 0.0):
                assert node.named_group == 3
            if np.isclose(node.coordinates[0], 1.0):
                assert node.named_group == 3
            if np.isclose(node.coordinates[0], 0.0):
                assert node.named_group == 3
    num_regression.check(
        {
            "geometrical_group": geometrical_group,
            "physical_group": physical_group,
            "named_group": named_group,
        }
    )
