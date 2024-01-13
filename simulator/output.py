from typing import Any
from pathlib import Path
import numpy.typing as npt

from simulator.constants import (
    RESULT_FILE_CURRENT_VERSION,
    NUMERIC_FILE_CURRENT_VERSION,
    DEBUG_FILE_CURRENT_VERSION,
)


class SimulatorLogger:
    # TODO: colocar o logger pra ca e criar ologger no simulator
    pass


class SimulatorOutputWriter:
    """
    This class handles the output of the simulator
    in order to save results or other variables data for future debug
    The models can implement
    """

    RESULT_FILENAME = "result.hdf5"
    NUMERIC_FILENAME = "numeric.hdf5"
    DEBUG_FILENAME = "debug.hdf5"

    def __init__(
        self,
        simulation_path: Path,
        description: str,
        must_save_result: bool,
        must_save_numeric: bool,
        must_save_debug: bool,
    ):
        self.simulation_path = simulation_path
        self.must_save_result = must_save_result
        self.must_save_numeric = must_save_numeric
        self.must_save_debug = must_save_debug
        # create and initialize the files
        self._create_result(description)
        self._create_numeric(description)
        self._create_debug(description)
        self.step_number = 0

    def _create_result(self, description: str):
        """Create the file handler for results data"""
        if self.must_save_result:
            self.result_file = h5py.File(
                self.simulation_path / self.RESULT_FILENAME, "w"
            )
            # holds mesh data like nodal positions and element groups, connectivity, etc.
            self.result_file.create_group("mesh")
            # holds all result i.e. nodal variables values at some timestep t_n
            self.result_file.create_group("result")
            # holds a simulation summary, e.g. total simulation time, total timesteps, etc.
            self.result_file.create_group("simulation")
            # write general data
            self.result_file["version"] = RESULT_FILE_CURRENT_VERSION
            self.result_file["description"] = description

    def _create_numeric(self, description: str):
        """
        Create the file handler for numeric data
        The models are free to decide how to organize their numeric output
        """
        if self.must_save_numeric:
            self.numeric_file = h5py.File(
                self.simulation_path / self.NUMERIC_FILENAME, "w"
            )
            # write general data
            self.numeric_file["version"] = RESULT_FILE_CURRENT_VERSION
            self.numeric_file["description"] = description

    def _create_debug(self, description: str):
        """
        Create the file handler for debug data
        The models are free to decide how to organize their debug output
        """
        if self.must_save_debug:
            self.debug_file = h5py.File(self.simulation_path / self.DEBUG_FILENAME, "w")
            # write general data
            self.debug_file["version"] = RESULT_FILE_CURRENT_VERSION
            self.debug_file["description"] = description

    def write_result(self, step_number: int, data: dict[str, npt.ArrayLike]) -> None:
        """Write results data to the hdf5"""
        self.step_number = step_number
        if self.must_save_result:
            path = f"result/t_{step_number}"
            for variable_name, values in data.items():
                self.result_file[f"{path}/{variable_name}"] = values

    def write_mesh(self):
        # TODO: implement write mesh method here
        pass

    def write_numeric(self, path: str, value):
        self.numeric_file[f"t_{self.step_number}/" + path.strip("/")] = value

    def write_debug(self, path: str, value):
        if self.must_save_debug:
            self.debug_file[f"t_{self.step_number}/" + path.strip("/")] = value
