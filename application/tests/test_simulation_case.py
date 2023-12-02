from pathlib import Path
from pytest_regressions.file_regression import FileRegressionFixture
import toml

from application.simulation_case import SimulationCase
from simulator.simulator import Simulator


def test_generate_cache_files_2d(
    data_regression: FileRegressionFixture,
    datadir: Path,
    case_corner_2d: SimulationCase,
):
    """generate all cached files needed for simulation"""
    cloned_case = case_corner_2d.clone(datadir)
    cloned_case.generate_cache_files()

    # ensure all simulation files were generated
    assert (datadir / "cache").exists()
    assert (datadir / "cache" / "cache_info.toml").exists()
    assert (datadir / "cache" / "simulation.toml").exists()

    info = toml.load(datadir / "cache" / "cache_info.toml")
    data_regression.check(info)

    simulation = toml.load(datadir / "cache" / "simulation.toml")
    data_regression.check(simulation, basename="simulation_toml")
