from pathlib import Path
import toml

from application.constants import SIMULATION_FILENAME
from application.preprocessor.mesh import Mesh


class SimulationPreprocessor:
    """This prepares the files for the simulator generation the input"""

    def __init__(self, simulation_path: Path):
        self.simulation_path = simulation_path
        self.simulation_data = toml.load(simulation_path / SIMULATION_FILENAME)
        self.validate_simulation_data()
        self.setup()

    def _process_mesh(self):
        # read the mesh
        logger.log.info(f"importing and setting the mesh: {mesh_filename}")
        mesh_filename = self.simulation_data["mesh"]["filename"]
        mesh = Mesh(
            self.simulation_path / mesh_filename,
            self.simulation_data["mesh"]["interpolation_order"],
        )
        # TODO: write the mesh to the hdf5 file

    def _process_domain_conditions(self):
        # create the domain conditions
        logger.log.info(f"importing and processing the domain conditions...")
        # TODO: write the conditions file to replace groupnames by numbers

    def setup(self):
        """Setup all is needed to build a simulation"""
        logger.log.info("Doing the setup for the simulation")
        model_name = self.simulation_data["simulation"]["model"]
        logger.log.info(f"set the model: {model_name}")
        self._process_mesh()
        self._process_domain_conditions()
        logger.log.info("All simulation setup done!")
