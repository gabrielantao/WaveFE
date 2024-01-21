import pytest
import numpy as np
import glob

from application.constants import PATH_CBS_MODELS, PATH_SCRIPTS
from simulator.case_regression import CaseRegressionTest
from simulator.cbs_models.models_register import AVAILABLE_MODELS
from simulator.simulator import Simulator
from simulator.element import Node, ElementsContainer
from simulator.element_enums import ElementType
from simulator.domain_conditions import DomainConditions
from application.constants import DOMAIN_CONDITIONS_FILENAME
from numba import typed


@pytest.fixture
def connectivity_matrix(shared_datadir):
    connectivity = np.loadtxt(
        shared_datadir / "old_square_cavity/connectivity.csv",
        delimiter=",",
        dtype=np.int32,
    )
    # these values are in csv shifted a unit so it should be sfited back
    return connectivity - 1


@pytest.fixture
def coordinate_matrix(shared_datadir):
    return np.loadtxt(
        shared_datadir / "old_square_cavity/coordinates.csv",
        delimiter=",",
        dtype=np.float64,
    )


def change_mesh(mesh, connectivity_matrix, shared_datadir):
    # modify the node positions
    nodes = []
    mesh.named_groups = {"surface": 1, "top": 2, "no-slip": 3, "reference": 4}

    # nodal data and group
    nodes_data = np.loadtxt(
        shared_datadir / "old_square_cavity/nodes_group_data.csv",
        delimiter=",",
        dtype=np.float64,
    )
    for x, y, named_group in nodes_data:
        node = Node(np.array([x, y]))
        node.named_group = int(named_group)
        nodes.append(node)

    mesh.nodes_handler.nodes = typed.List(nodes)
    # create and fill the elements
    mesh.element_containers[ElementType.TRIANGLE.value] = ElementsContainer(
        ElementType.TRIANGLE.value, connectivity_matrix
    )
    return mesh


# TODO: maybe this should not be done without pytest
def test_cbs_semi_implicit(connectivity_matrix, coordinate_matrix, shared_datadir):
    case_path = PATH_CBS_MODELS / "models/semi_implicit/cases/square_cavity"
    # TODO: save the results in cache folder do not copy result to its own directory
    simulator = Simulator(case_path)
    # TODO: change this to run the case for other generated mesh (gmesh)
    simulator.mesh = change_mesh(simulator.mesh, connectivity_matrix, shared_datadir)
    # recreate domain conditions with modified mesh
    simulator.domain_conditions = DomainConditions(
        simulator.simulation_path / DOMAIN_CONDITIONS_FILENAME,
        simulator.mesh,
        simulator.model.get_default_initial_values(
            simulator.mesh.nodes_handler.dimensions
        ),
    )
    # check if mesh was modified
    assert simulator.mesh.nodes_handler.total_nodes == 2601
    assert (
        simulator.mesh.element_containers[ElementType.TRIANGLE.value].element_type
        == ElementType.TRIANGLE.value
    )
    assert (
        len(simulator.mesh.element_containers[ElementType.TRIANGLE.value].elements)
        == 5000
    )
    simulator.run()
