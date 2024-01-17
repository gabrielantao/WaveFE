from pathlib import Path
import logging
from simulator.simulation_case import SimulationCase
from application.constants import SIMULATION_LOG_PATH


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
