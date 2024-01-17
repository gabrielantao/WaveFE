from pathlib import Path
import pytest

from simulator.simulation_case import SimulationCase


@pytest.fixture
def case_corner_2d(shared_datadir: Path):
    return SimulationCase(shared_datadir / "dummy_case")


@pytest.fixture
def simulator_cbs():
    pass
