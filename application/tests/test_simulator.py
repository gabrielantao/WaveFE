from pathlib import Path
from pytest_regressions.file_regression import FileRegressionFixture
from pytest_regressions.num_regression import NumericRegressionFixture
import toml
import h5py

from application.simulation_case import SimulationCase
import numpy as np


# TODO: mock the generated input.hdf5 to the created manually
def test_cbs_semi_implicit(shared_datadir):
    case_corner_2d = SimulationCase(shared_datadir / "dummy_case")
    # TODO: mock the call for the simulation just to get a ping
    case_corner_2d.run()
    # TODO: do the regression here


# TODO: create a script to run all validation tests (create it in the core directory)
