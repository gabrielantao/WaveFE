import numpy as np
from pytest_regressions.data_regression import DataRegressionFixture
from simulator.mesh import Mesh
from simulator.element import ElementType


# TODO: implement tests for import the different mesh input formats


def test_import_mesh(shared_datadir, data_regression):
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
    # convert numpy into lists to do the regression
    regression_data = {}
    for name, named_group_data in mesh.named_groups.items():
        regression_data[name] = {
            element_type: values.tolist()
            for element_type, values in named_group_data.items()
        }
    data_regression.check(regression_data)
