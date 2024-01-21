from pathlib import Path
import logging
import toml

from application.constants import (
    SIMULATION_FILENAME,
    DOMAIN_CONDITIONS_FILENAME,
    SIMULATION_LOG_PATH,
    SIMULATION_RESULT_PATH,
    SIMULATION_TEMP_PATH,
)
from simulator.mesh import Mesh
from simulator.domain_conditions import DomainConditions
from simulator.cbs_models.models_register import AVAILABLE_MODELS
from simulator.output import SimulatorOutputWriter


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
        # simulation general logger
        # TODO: add option for the log level in input file
        self.logging_level = logging.INFO
        self.logger = logging.getLogger("simulator")
        self.logger_handler = logging.FileHandler(
            simulation_path / SIMULATION_LOG_PATH / "simulation.log", mode="w"
        )
        self.logger.addHandler(self.logger_handler)
        self.logger.setLevel(self.logging_level)
        self.logger.info("Starting simulator...")
        self.validate_simulation_data()
        self.setup()
        # just log the success
        case_alias = self.simulation_data["general"]["alias"]
        case_title = self.simulation_data["general"]["title"]
        logging.info(
            "simulation created and ready\ncase: %s\t[%s]", case_title, case_alias
        )

    def validate_simulation_data(self):
        """
        Validate the values for simulation.toml file
        """
        self.logger.info("doing logical validation of the simulation.toml")
        # check if solver options are correct
        if self.simulation_data["solver"]["name"] not in self.SOLVER_OPTIONS:
            self.logger.error(
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
            self.logger.error(
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
            self.logger.error(
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
                self.logger.error(
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
                self.logger.error(
                    "Tolerance %s should have all variables %s",
                    tolerance_type,
                    ", ".join(model.VARIABLES),
                )
                raise RuntimeError(
                    "An error occuried during validation. See the log for more information"
                )
        self.logger.info("logical validation of the simulation.toml success!")

    def setup(self):
        """Setup all is needed to build a simulator"""
        model_name = self.simulation_data["simulation"]["model"]
        mesh_filename = self.simulation_data["mesh"]["filename"]

        self.logger.info("Doing the setup for the simulator")
        self.logger.info(f"set the model: {model_name}")
        self.logger.info(f"set the mesh: {mesh_filename}")

        # import and setup the model
        self.logger.info(f"setting the model...")
        self.model = AVAILABLE_MODELS[model_name]

        # create the mesh
        self.logger.info(f"importing and setting the mesh...")
        self.mesh = Mesh(
            self.simulation_path / mesh_filename,
            self.simulation_data["mesh"]["interpolation_order"],
        )
        # create the domain conditions
        self.logger.info(f"importing and setting the domain conditions...")
        self.domain_conditions = DomainConditions(
            self.simulation_path / DOMAIN_CONDITIONS_FILENAME,
            self.mesh,
            self.model.get_default_initial_values(self.mesh.nodes_handler.dimensions),
        )

        # set the output manager
        self.logger.info(f"setting the output manager...")
        self.output_manager = SimulatorOutputWriter(
            self.simulation_path,
            self.simulation_data["general"]["description"],
            self.simulation_data["output"]["save_result"],
            self.simulation_data["output"]["save_numeric"],
            self.simulation_data["output"]["save_debug"],
        )

        self.logger.info("All simulator setup done!")

    def get_model_parameters(self, dimension):
        """
        Return data from simulation data file relevant to the model processing
        This method can add new parameters that don't come from the input simulation file
        """
        model_parameters = self.simulation_data.copy()
        model_parameters.pop("general")
        model_parameters["mesh"]["dimension"] = dimension
        return model_parameters

    def run(self) -> None:
        """Main function to run simulator based on assembling functions configured for the model"""
        self.logger.info("Start simulation")
        step_limit = self.simulation_data["simulation"]["steps_limit"]
        dimension = self.mesh.nodes_handler.dimensions
        self.logger.info("get simulation parameters")
        simulation_parameters = self.get_model_parameters(dimension)
        self.logger.info("setup the model")
        self.model.setup(self.logger_handler, simulation_parameters)
        self.logger.info("apply initial conditions")
        self.model.apply_initial_default_values(self.mesh.nodes_handler)
        self.domain_conditions.apply_initial_conditions(self.mesh.nodes_handler)

        self.logger.info("start simulator main loop...")
        # run the simulation main loop
        for step_number in range(step_limit):
            self.logger.info(
                f"Solving time step {step_number} of {step_limit} (max)..."
            )

            must_save_current_result = (
                step_number % simulation_parameters["output"]["frequency"] == 0
            )
            iteraction_report = self.model.run_iteration(
                self.mesh,
                self.domain_conditions,
                self.output_manager,
                simulation_parameters,
                step_number,
            )
            if must_save_current_result:
                self.output_manager.write_result(simulation_parameters)
            if iteraction_report.stop_simulation:
                if iteraction_report.converged:
                    self.logger.info(iteraction_report.status_message)
                else:
                    self.logger.error(iteraction_report.status_message)
                # if the result was not saved for this timestep,
                # then force the saving to help debuging process
                if not must_save_current_result:
                    self.output_manager.write_result(simulation_parameters)
                break
            # TODO: should check here if the result is diverging for some amount of time steps
            #       calculate the difference between current and old variable values
            # TODO: print dynamic log in terminal for the evolution of vars difference and log it in the file as well
        if step_number == step_limit:
            self.logger.error(
                f"Maximum time step {step_limit} was reached without convergence."
            )
