from pathlib import Path
import logging
import toml

from application.constants import SIMULATION_FILENAME, DOMAIN_CONDITIONS_FILENAME
from simulator.mesh import Mesh
from simulator.domain_conditions import DomainConditions
from simulator.models.models_register import AVAILABLE_MODELS


class Simulator:
    """
    The class deals with all simulation aspects.
    It configures and invokes the model iteration
    """

    SOLVER_OPTIONS = ["Conjugate Gradient"]
    PRECONDITIONER_OPTIONS = ["Jacobi"]

    def __init__(self, simulation_path: Path):
        self.simulation_path = simulation_path
        self.simulation_data = toml.load(simulation_path / SIMULATION_FILENAME)
        self.validate_simulation_data()
        self.setup()
        case_alias = self.simulation_data["general"]["alias"]
        case_title = self.simulation_data["general"]["title"]
        logging.info(
            "simulation created and ready\ncase: %s\t[%s]", case_title, case_alias
        )

    def validate_simulation_data(self):
        """
        Validate the values for simulation.toml file
        """
        logging.info("doing logical validation of the simulation.toml")
        # check if solver options are correct
        if self.simulation_data["solver"]["name"] not in self.SOLVER_OPTIONS:
            logging.error(
                "The simulator do not have the solver %s available.\nThe list of available solvers is: %s",
                self.simulation_data["solver"]["name"],
                ", ".join(self.SOLVER_OPTIONS),
            )
            raise RuntimeError(
                "An error occuried during validation. See the log for more information"
            )
        if (
            self.simulation_data["solver"]["preconditioner"]
            not in self.PRECONDITIONER_OPTIONS
        ):
            logging.error(
                "The simulator do not have the solver %s available.\nThe list of available solvers is: %s",
                self.simulation_data["solver"]["preconditioner"],
                ", ".join(self.PRECONDITIONER_OPTIONS),
            )
            raise RuntimeError(
                "An error occuried during validation. See the log for more information"
            )
        # check if model in simulation.toml fileis available
        model_name = self.simulation_data["simulation"]["model"]
        if model_name not in AVAILABLE_MODELS:
            logging.error(
                "The model %s is not available.\nThe list of available models is: %s",
                model_name,
                ", ".join(AVAILABLE_MODELS.keys()),
            )
            raise RuntimeError(
                "An error occuried during validation. See the log for more information"
            )
        model = AVAILABLE_MODELS[self.simulation_data["simulation"]["model"]]
        # check the output variables if they are valid variables for the model
        for output_variables in self.simulation_data["output"]["variables"]:
            if output_variables not in model.VARIABLES:
                logging.error(
                    "Invalid variable %s for the model %s.\nThe list of variables for this model is: %s",
                    output_variables,
                    model_name,
                    ", ".join(model.VARIABLES),
                )
                raise RuntimeError(
                    "An error occuried during validation. See the log for more information"
                )
        # check the same variables used in tolerance section
        for tolerance_type in ["relative", "absolute"]:
            variables = set(
                self.simulation_data["simulation"][f"tolerance_{tolerance_type}"].keys()
            )
            if not variables == set(model.VARIABLES):
                logging.error(
                    "Tolerance %s should have all variables %s",
                    tolerance_type,
                    ", ".join(model.VARIABLES),
                )
                raise RuntimeError(
                    "An error occuried during validation. See the log for more information"
                )
        logging.info("logical validation of the simulation.toml success!")

    def setup(self):
        """Setup all is needed to build a simulator"""
        # import and setup the model
        self.model = AVAILABLE_MODELS[self.simulation_data["simulation"]["model"]]()
        # create the mesh
        self.mesh = Mesh(
            self.simulation_path / self.simulation_data["mesh"]["filename"],
            self.simulation_data["mesh"]["interpolation_order"],
        )
        # create the domain conditions
        self.domain_conditions = DomainConditions(
            self.simulation_path / DOMAIN_CONDITIONS_FILENAME,
            self.mesh,
            self.model.get_default_initial_values(self.mesh.nodes_handler.dimensions),
        )

    def get_model_parameters(self):
        """Return data from simulation data file relevant to the model processing"""
        model_parameters = self.simulation_data.copy()
        model_parameters.pop("general")
        return model_parameters

    def run(self):
        """Main function to run simulator based on assembling functions configured for the model"""
        simulation_parameters = self.get_model_parameters()
        step_limit_reached = True
        for step_number in range(self.simulation_data["simulation"]["step_limit"]):
            iteraction_report = self.model.run_iteration(
                self.mesh, self.domain_conditions, simulation_parameters
            )
            # TODO: check if step limit was reached
            # TODO: write results to the hdf here
            # TODO: log the report message
