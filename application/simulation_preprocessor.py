from pathlib import Path
import toml
import h5py

from application.constants import SIMULATION_FILENAME, SIMULATION_INPUT_DATA_FILENAME
from application.preprocessor.mesh import Mesh


class SimulationPreprocessor:
    """This prepares the files for the simulator generation the input"""

    def __init__(self, cache_path: Path):
        self.cache_path = cache_path
        with open(cache_path / DOMAIN_CONDITIONS_FILENAME, "r") as f:
            self.domain_conditions_data = toml.load(f)
        with open(cache_path / SIMULATION_FILENAME, "r") as f:
            self.simulation_data = toml.load(f)
        self.setup()

    def _process_mesh(self, mesh):
        """Preprocess the mesh data to write to the input hdf5"""
        input_file = h5py.File(self.cache_path / SIMULATION_INPUT_DATA_FILENAME, "w")
        mesh_group = input_file.create_group("mesh")
        mesh_group["dimension"] = mesh.dimension

        # write the nodes data to the input file
        nodes_group = mesh_group.create_group("nodes")
        nodes_group["physical_groups"] = mesh.nodes_handler.coordinates
        nodes_group["geometrical_groups"] = mesh.nodes_handler.geometrical_group
        nodes_group["domain_condition_groups"] = (
            mesh.nodes_handler.domain_condition_groups
        )
        nodes_group["positions"] = mesh.nodes_handler.coordinates
        nodes_group["velocities"] = mesh.nodes_handler.velocities
        nodes_group["accelerations"] = mesh.nodes_handler.accelerations

        # write the connectivity data to the input file
        for element_container in mesh.get_element_containers():
            element_container_group = mesh_group.create_group(
                element_container.element_type.value
            )
            element_container_group["connectivity"] = element_container.connectivity
            # TODO [implement group of elements]
            ## write groups of elements here

    def _process_domain_conditions(self, mesh):
        """Preprocess the domain conditions file"""
        # create the domain conditions
        logger.log.info(f"importing and processing the domain conditions...")
        for i in range(len(self.domain_conditions_data["initial"])):
            group_name = self.domain_conditions_data["initial"][i]["group_name"]
            group_number = mesh.domain_condition_groups[group_name]
            # replace the name of group by its number
            self.domain_conditions_data["initial"][i]["group_name"] = group_number
        # replace the original file by the processed file
        with open(self.cache_path / DOMAIN_CONDITIONS_FILENAME, "w") as f:
            toml.dump(self.domain_conditions_data, f)

    def setup(self):
        """Setup all is needed to build a simulation"""
        logger.log.info("Doing the setup for the simulation")
        model_name = self.simulation_data["simulation"]["model"]
        logger.log.info(f"set the model: {model_name}")
        # read the mesh
        logger.log.info(f"importing and setting the mesh: {mesh_filename}")
        mesh = Mesh(
            self.simulation_path / self.simulation_data["mesh"]["filename"],
            self.simulation_data["mesh"]["interpolation_order"],
        )
        self._process_mesh(mesh)
        self._process_domain_conditions(mesh)
        logger.log.info("All simulation setup done!")
