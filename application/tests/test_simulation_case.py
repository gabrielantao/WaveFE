from pathlib import Path
from pytest_regressions.file_regression import FileRegressionFixture
from pytest_regressions.num_regression import NumericRegressionFixture
import toml
import h5py

from application.simulation_case import SimulationCase
import numpy as np


def test_generate_cache_files_2d(
    data_regression: FileRegressionFixture,
    num_regression: NumericRegressionFixture,
    shared_datadir: Path,
):
    """generate all cached files needed for simulation"""
    # cloned_case = case_corner_2d.clone(datadir)
    case_corner_2d = SimulationCase(shared_datadir / "dummy_case")
    case_corner_2d._generate_cache_files()

    # ensure all simulation files were generated
    cache_filepath = shared_datadir / "dummy_case" / "cache"
    assert cache_filepath.exists()
    assert (cache_filepath / "cache_info.toml").exists()
    assert (cache_filepath / "simulation.toml").exists()
    assert (cache_filepath / "conditions.toml").exists()
    assert (cache_filepath / "square_cavity.msh").exists()
    assert (cache_filepath / "log").exists()
    assert (cache_filepath / "temp").exists()
    assert (cache_filepath / "result").exists()

    info = toml.load(cache_filepath / "cache_info.toml")
    data_regression.check(info)

    simulation = toml.load(cache_filepath / "simulation.toml")
    data_regression.check(simulation, basename="simulation_toml")
    domain_conditions = toml.load(cache_filepath / "conditions.toml")
    data_regression.check(domain_conditions, basename="conditions_toml")


def test_generate_input_2d(
    data_regression: FileRegressionFixture,
    num_regression: NumericRegressionFixture,
    shared_datadir: Path,
):
    """generate all cached files needed for simulation"""
    # cloned_case = case_corner_2d.clone(datadir)
    case_corner_2d = SimulationCase(shared_datadir / "dummy_case")
    case_corner_2d._generate_cache_files()

    # test the input file with mesh data
    cache_filepath = shared_datadir / "dummy_case" / "cache"
    input_file = h5py.File(cache_filepath / "input.hdf5", "r")
    assert np.array(input_file["mesh"]["dimension"]) == np.array(2)
    # test nodes groups
    num_regression.check(
        {
            "physical": input_file["mesh"]["nodes"]["physical_groups"],
            "geometrical": input_file["mesh"]["nodes"]["geometrical_groups"],
            "domain_condition": input_file["mesh"]["nodes"]["domain_condition_groups"],
        },
        basename="input_2d_nodes_groups",
    )

    # nodes kinematics data
    assert input_file["mesh"]["nodes"]["positions"].shape == (2129, 2)
    assert input_file["mesh"]["nodes"]["velocities"].shape == (2129, 2)
    assert input_file["mesh"]["nodes"]["accelerations"].shape == (2129, 2)
    num_regression.check(
        {
            "positions_x": input_file["mesh"]["nodes"]["positions"][:, 0],
            "positions_y": input_file["mesh"]["nodes"]["positions"][:, 1],
            "velocities_x": input_file["mesh"]["nodes"]["velocities"][:, 0],
            "velocities_y": input_file["mesh"]["nodes"]["velocities"][:, 1],
            "accelerations_x": input_file["mesh"]["nodes"]["accelerations"][:, 0],
            "accelerations_y": input_file["mesh"]["nodes"]["accelerations"][:, 1],
        },
        basename="input_2d_nodes_kinematics",
    )

    # test elements
    assert "segments" not in input_file["mesh"].keys()
    assert "triangles" in input_file["mesh"].keys()
    assert "quadrilaterals" not in input_file["mesh"].keys()
    assert input_file["mesh"]["triangles"]["connectivity"].shape == (4088, 3)
    num_regression.check(
        {
            "node_index_1": input_file["mesh"]["triangles"]["connectivity"][:, 0],
            "node_index_2": input_file["mesh"]["triangles"]["connectivity"][:, 1],
            "node_index_3": input_file["mesh"]["triangles"]["connectivity"][:, 2],
        },
        basename="input_2d_element_triangle_connectivity",
    )
