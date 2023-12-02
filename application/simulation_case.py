import shutil
import hashlib
from pathlib import Path
from datetime import datetime
import logging
import toml
from pathlib import Path

from application.validator import (
    validate_input_file,
    InputFileType,
)


class SimulationCase:
    """This class hadles a case."""

    # default name for some files
    DOMAIN_CONDITIONS_FILENAME = "conditions.toml"
    SIMULATION_FILENAME = "simulation.toml"

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
        # TODO: check if this validation function should be two different functions
        # one for conditions and other for simualtion files
        self.simulation_data = validate_input_file(
            self.folder / self.SIMULATION_FILENAME,
            InputFileType.SIMULATION,
        )
        self.conditions_data = validate_input_file(
            folder / self.DOMAIN_CONDITIONS_FILENAME,
            InputFileType.DOMAIN_CONDITIONS,
        )
        # get input file checksum
        self.input_files_checksum = {}
        with open(folder / self.SIMULATION_FILENAME, "rb") as f:
            self.input_files_checksum["simulation"] = hashlib.md5(f.read()).hexdigest()
        with open(folder / self.DOMAIN_CONDITIONS_FILENAME, "rb") as f:
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

    def write_simulation_info_file(self):
        """Write data for simulation files with new set values"""
        logging.info(f"generating simulation file to cache in {self.cache_folder}")
        with open(self.cache_folder / "simulation.toml", "w", encoding="utf-8") as f:
            toml.dump(self.simulation_data, f)

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
            logging.info(f"writing cache information {cache_info_filepath}")
            self.write_simulation_info_file()
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

    def run(self, simulator) -> None:
        """Call simulator to run this case"""
        case_alias = self.simulation_data["general"]["alias"]
        case_title = self.simulation_data["general"]["title"]
        logging.info(f"title: {case_title}\t[{case_alias}]")
        self.generate_cache_files()
        # run main core function
        simulator.start(self.cache_folder)
        # copy cached result folder to case_path/results/datetime
        self.last_result_folder = self.result_folder / Path(
            datetime.now().strftime("%Y_%m_%d %H_%M_%S")
        )
        shutil.copytree(
            self.cache_result_folder, self.last_result_folder, dirs_exist_ok=True
        )
