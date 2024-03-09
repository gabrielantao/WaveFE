import shutil
import hashlib
from pathlib import Path
from datetime import datetime
import logging
import toml
from pathlib import Path
import subprocess
import os

from application.constants import (
    WAVE_PATH_SIMULATOR,
    SIMULATION_FILENAME,
    DOMAIN_CONDITIONS_FILENAME,
    SIMULATION_CACHE_PATH,
    SIMULATION_LOG_PATH,
    SIMULATION_RESULT_PATH,
    SIMULATION_TEMP_PATH,
)
from application.validator import (
    validate_input_file,
    InputFileType,
)
from application.simulation_preprocessor import SimulationPreprocessor
from application.logger import logger


class SimulationCase:
    """This class hadles a case."""

    def __init__(self, folder: Path):
        """folder is an absolute path"""
        # ensure absolute path for folder
        self.case_folder = folder.resolve()
        self.cache_folder = self.case_folder / SIMULATION_CACHE_PATH
        # run validations and load data from input files
        self.simulation_data = validate_input_file(
            self.case_folder / SIMULATION_FILENAME,
            InputFileType.SIMULATION,
        )
        self.conditions_data = validate_input_file(
            folder / DOMAIN_CONDITIONS_FILENAME,
            InputFileType.DOMAIN_CONDITIONS,
        )
        self._create_cache_folder()
        # get input file checksum
        self.input_files_checksum = {}
        with open(folder / SIMULATION_FILENAME, "rb") as f:
            self.input_files_checksum["simulation"] = hashlib.md5(f.read()).hexdigest()
        with open(folder / DOMAIN_CONDITIONS_FILENAME, "rb") as f:
            self.input_files_checksum["conditions"] = hashlib.md5(f.read()).hexdigest()
        with open(folder / self.simulation_data["mesh"]["filename"], "rb") as f:
            self.input_files_checksum["mesh"] = hashlib.md5(f.read()).hexdigest()

    def _create_cache_folder(self):
        """Create folders to be used as cache for the simulation case"""
        (self.case_folder / SIMULATION_CACHE_PATH).mkdir(exist_ok=True)
        self.cache_log_folder = self.case_folder / SIMULATION_LOG_PATH
        self.cache_temp_folder = self.case_folder / SIMULATION_TEMP_PATH
        self.cache_result_folder = self.case_folder / SIMULATION_RESULT_PATH
        # create the paths if they don't exist
        self.cache_log_folder.mkdir(parents=True, exist_ok=True)
        self.cache_temp_folder.mkdir(parents=True, exist_ok=True)
        self.cache_result_folder.mkdir(parents=True, exist_ok=True)

    def _copy_input_files_to_cache(self):
        """Copy the simulation, domain conditions and the mesh file to the cache temp folder"""
        logging.info("copying simulation file to cache in %s", self.cache_folder)
        shutil.copy(
            self.case_folder / SIMULATION_FILENAME,
            self.cache_folder / SIMULATION_FILENAME,
        )
        shutil.copy(
            self.case_folder / DOMAIN_CONDITIONS_FILENAME,
            self.cache_folder / DOMAIN_CONDITIONS_FILENAME,
        )
        shutil.copy(
            self.case_folder / self.simulation_data["mesh"]["filename"],
            self.cache_folder / self.simulation_data["mesh"]["filename"],
        )

    def _generate_cache_files(self) -> None:
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
            self._copy_input_files_to_cache()
            cache_info = {
                "general": self.simulation_data["general"],
                "checksum": self.input_files_checksum,
            }
            with open(cache_info_filepath, "w", encoding="utf-8") as f:
                toml.dump(cache_info, f)
            # redo the preprocessing of cached files if needed
            SimulationPreprocessor(self.cache_folder).setup()
        else:
            logging.info(
                "no parameters have changed for this simulation since last run"
            )

    def clean_cache(self) -> None:
        """Remove cache folder and its cached content"""
        if self.cache_folder.exists():
            shutil.rmtree(self.cache_folder)

    def clone(self, destiny_folder: Path):
        """Clone case folder to destiny folder and return the cloned case"""
        shutil.copytree(self.case_folder, destiny_folder, dirs_exist_ok=True)
        return SimulationCase(destiny_folder)

    def run(self) -> None:
        """Call simulator to run this case"""
        self._generate_cache_files()
        # run the simulator
        subprocess.run(
            [
                "pixi",
                "run",
                "wave",
                str(self.case_folder),
            ],
            cwd=WAVE_PATH_SIMULATOR,
        )
        # copy cached result folder to case_path/results/datetime
        # TODO: put this here to save the case
        # self.last_result_folder = (
        #     self.case_folder
        #     / Path("results")
        #     / Path(datetime.now().strftime("%Y_%m_%d %H_%M_%S"))
        # )
        # shutil.copytree(self.cache_folder, self.last_result_folder, dirs_exist_ok=True)
