import shutil
import hashlib
from pathlib import Path
from datetime import datetime
import logging
import toml
from pathlib import Path

from application.constants import SIMULATION_FILENAME, DOMAIN_CONDITIONS_FILENAME
from application.validator import (
    validate_input_file,
    InputFileType,
)
from simulator.simulator import Simulator


class SimulationCase:
    """This class hadles a case."""

    def __init__(self, folder: Path):
        """folder is an absolute path"""
        # ensure absolute path for folder
        self.folder = folder.resolve()
        self.cache_folder = folder / Path("cache")
        self.figure_folder = folder / Path("figure")
        self.mesh_folder = folder / Path("mesh")
        self.reference_folder = folder / Path("reference")
        self.result_folder = folder / Path("result")
        self.last_result_folder = Path("result")
        self.create_cache_folder()
        # read and run validations
        self.simulation_data = validate_input_file(
            self.folder / SIMULATION_FILENAME,
            InputFileType.SIMULATION,
        )
        self.conditions_data = validate_input_file(
            folder / DOMAIN_CONDITIONS_FILENAME,
            InputFileType.DOMAIN_CONDITIONS,
        )
        # get input file checksum
        self.input_files_checksum = {}
        with open(folder / SIMULATION_FILENAME, "rb") as f:
            self.input_files_checksum["simulation"] = hashlib.md5(f.read()).hexdigest()
        with open(folder / DOMAIN_CONDITIONS_FILENAME, "rb") as f:
            self.input_files_checksum["conditions"] = hashlib.md5(f.read()).hexdigest()
        with open(folder / self.simulation_data["mesh"]["filename"], "rb") as f:
            self.input_files_checksum["mesh"] = hashlib.md5(f.read()).hexdigest()

    def create_cache_folder(self):
        """Create folders to be used as cache for the simulation case"""
        self.cache_log_folder = self.cache_folder / Path("log")
        self.cache_temp_folder = self.cache_folder / Path("temp")
        self.cache_result_folder = self.cache_folder / Path("result")
        self.cache_folder.mkdir(exist_ok=True)
        self.cache_log_folder.mkdir(parents=True, exist_ok=True)
        self.cache_temp_folder.mkdir(parents=True, exist_ok=True)
        self.cache_result_folder.mkdir(parents=True, exist_ok=True)

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

    def copy_input_files_to_cache(self):
        """Copy the simulation and domain conditions file to the cache folder"""
        logging.info("copying simulation file to cache in %s", self.cache_folder)
        shutil.copy(
            self.folder / SIMULATION_FILENAME, self.cache_folder / SIMULATION_FILENAME
        )
        shutil.copy(
            self.folder / DOMAIN_CONDITIONS_FILENAME,
            self.cache_folder / DOMAIN_CONDITIONS_FILENAME,
        )
        shutil.copy(
            self.folder / self.simulation_data["mesh"]["filename"],
            self.cache_folder / self.simulation_data["mesh"]["filename"],
        )

    def generate_cache_files(self) -> None:
        """Check if cached files are updated and regenerate them if they're not updated"""

        cache_info_filepath = self.cache_folder / Path("cache_info.toml")
        must_generate_files = True
        # check changes in file
        if cache_info_filepath.exists():
            cache_data = toml.load(cache_info_filepath)
            must_generate_files = not (
                cache_data["checksum"]["simulation"]
                == self.input_files_checksum["simulation"]
                and cache_data["checksum"]["conditions"]
                == self.input_files_checksum["conditions"]
                and cache_data["checksum"]["mesh"] == self.input_files_checksum["mesh"]
            )
        if must_generate_files:
            logging.info("writing cache information %s", cache_info_filepath)
            self.copy_input_files_to_cache()
            cache_info = {
                "general": self.simulation_data["general"],
                "checksum": self.input_files_checksum,
            }
            with open(cache_info_filepath, "w", encoding="utf-8") as f:
                toml.dump(cache_info, f)
        logging.info("no parameters have changed for this simulation since last run")

    def clean_cache(self) -> None:
        """Remove cache folder and its cached content"""
        if self.cache_folder.exists():
            shutil.rmtree(self.cache_folder)

    def clone(self, destiny_folder: Path):
        """Clone case folder to destiny folder and return the cloned case"""
        shutil.copytree(self.folder, destiny_folder, dirs_exist_ok=True)
        return SimulationCase(destiny_folder)

    def run(self) -> None:
        """Call simulator to run this case"""
        self.generate_cache_files()
        # run the simulator
        simulator = Simulator(self.cache_folder)
        simulator.run()
        # copy cached result folder to case_path/results/datetime
        self.last_result_folder = self.result_folder / Path(
            datetime.now().strftime("%Y_%m_%d %H_%M_%S")
        )
        shutil.copytree(
            self.cache_result_folder, self.last_result_folder, dirs_exist_ok=True
        )
