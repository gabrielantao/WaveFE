from pathlib import Path

from application.constants import SIMULATION_LOG_PATH
from application.logger import logger
from application.simulation_case import SimulationCase


# TODO: maybe this should go to the simulator itself to run as case validator
class CaseRegressionTest:
    """Make the case regression to compare if current result matches the reference result"""

    def __init__(self, case_folder: Path):
        self.case = SimulationCase(case_folder)
        self.reference_folder = case_folder / "reference"
        self.logging_level = logging.INFO
        self.logger = logging.getLogger("case-regression")
        self.logger.addHandler(
            logging.FileHandler(
                case_folder / SIMULATION_LOG_PATH / f"regression.log", mode="w"
            )
        )
        self.logger.setLevel(self.logging_level)
        self.logger.info("Starting case regression test...")
        # TODO: should first check if result doens't exist

        # TODO: it should get a reference_folder and pass it to the data loader
        # it should read some variables from reference cases to numpy arrays and make regression
        # it should be able to update reference data

    # TODO: check if a reference result save simulation parameters (just like any other regular result)
    # in this way the user always can track the parameters set in simulation.toml
    # def get_reference_result(self) -> Path:
    #     """Return the reference result for this case."""
    #     filepath = self.reference_folder / self.RESULT_FILENAME
    #     with h5py.File(filepath, "r") as result:
    #         return result

    # def get_obtained_result(self):
    #     """Return the last obtained result for this case."""
    #     filepath = self.result_folder / self.last_result_folder / self.RESULT_FILENAME
    #     with h5py.File(filepath, "r") as result:
    #         return result
