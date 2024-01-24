from typing import Any
from pathlib import Path
import logging
from scipy import sparse
import numpy as np

from simulator.cbs_models.abstract_model import AbstractCBSModel
from simulator.assembler import Assembler, EquationSide
from simulator.element import ElementType
from simulator.cbs_models.models.semi_implicit.elements_assembling import (
    assemble_mass_lumped_lhs,
    assemble_mass_lhs,
    assemble_stiffness_lhs,
    assemble_element_rhs_step_1,
    assemble_element_rhs_step_2,
    assemble_element_rhs_step_3,
)
from simulator.cbs_models.report_result import IterationReport, IterationStatusMessage
from simulator.cbs_models.model_equation import ModelEquation
from simulator.convergence_checker import check_convergence


class CBSSemiImplicit(AbstractCBSModel):
    """A CBS semi-implicit basic model"""

    def __init__(self):
        self.VARIABLES = ["u_1", "u_2", "u_3", "p"]
        self.DEFAULT_INITIAL_VALUES = {"u_1": 0.0, "u_2": 0.0, "u_3": 0.0, "p": 0.0001}

    def setup(self, logger_handler, simulation_parameters: dict[str, Any]):
        """Setup functions used for assembling process"""

        # setup the logger
        self.logger = logging.getLogger("simulation-model")
        self.logger.addHandler(logger_handler)
        # TODO: add option for the log level in input file
        self.logging_level = logging.INFO
        self.logger.setLevel(self.logging_level)
        self.logger.info(f"Doing the model setup...")

        # setup an assembler instance for this model
        self.logger.info(f"doing setup of assembler setup")
        self.assembler = Assembler()

        # check if it should use lumped mass to solve the problem
        use_lumped_mass = not simulation_parameters["simulation"]["transient"]

        self.logger.info(f"doing setup of assembling equations")

        #################################
        ### CREATE EQUATION OF STEP 1 ###
        #################################
        variables_1 = [
            f"u_{i + 1}" for i in range(simulation_parameters["mesh"]["dimension"])
        ]
        assembled_elements_1 = [
            {
                "element_type": ElementType.TRIANGLE,
                "lhs": assemble_mass_lumped_lhs
                if use_lumped_mass
                else assemble_mass_lhs,
                "rhs": assemble_element_rhs_step_1,
            },
            # TODO: register other elements assembled here...
        ]
        equation_1 = ModelEquation(
            "step 1",
            variables_1,
            assembled_elements_1,
            self.assembler,
        )

        #################################
        ### CREATE EQUATION OF STEP 2 ###
        #################################
        assembled_elements_2 = [
            {
                "element_type": ElementType.TRIANGLE,
                "lhs": assemble_stiffness_lhs,
                "rhs": assemble_element_rhs_step_2,
            },
            # TODO: register other elements assembled here...
        ]
        equation_2 = ModelEquation(
            "step 2", ["p"], assembled_elements_2, self.assembler
        )

        #################################
        ### CREATE EQUATION OF STEP 3 ###
        #################################
        variables_3 = [
            f"u_{i + 1}" for i in range(simulation_parameters["mesh"]["dimension"])
        ]
        assembled_elements_3 = [
            {
                "element_type": ElementType.TRIANGLE,
                "lhs": assemble_mass_lumped_lhs
                if use_lumped_mass
                else assemble_mass_lhs,
                "rhs": assemble_element_rhs_step_3,
            },
            # TODO: register other elements assembled here...
        ]
        equation_3 = ModelEquation(
            "step 3",
            variables_3,
            assembled_elements_3,
            self.assembler,
        )

        # create the list of equations
        self.equations = [equation_1, equation_2, equation_3]
        self.logger.info(
            f"Registered equations ({len(self.equations)}): "
            + ", ".join([equation.label for equation in self.equations])
        )

    def get_variable_names(self, dimensions):
        """Get the list of model variables"""
        return [f"u_{dimension + 1}" for dimension in range(dimensions)] + ["p"]

    def get_default_initial_values(self, dimensions: int):
        """Get the initial values for all variables"""
        default_initial_values = self.DEFAULT_INITIAL_VALUES.copy()
        match dimensions:
            case 1:
                default_initial_values.pop("u_2")
                default_initial_values.pop("u_3")
                return default_initial_values
            case 2:
                default_initial_values.pop("u_3")
                return default_initial_values
            case 3:
                return default_initial_values

    def run_iteration(
        self,
        mesh,
        domain_conditions,
        output_manager,
        simulation_parameters,
        step_number: int,
    ) -> IterationReport:
        """Run the three steps of semi-implicit model"""
        # status variables
        success = False
        stop_simulation = False
        status_message = IterationStatusMessage.NORMAL

        must_update_lhs = mesh.nodes_handler.nodes_moved
        dimensions = mesh.nodes_handler.dimensions
        variables_names = self.get_variable_names(dimensions)

        # update elements internal data
        if mesh.nodes_handler.nodes_moved:
            self.logger.info(
                "update the element parameters, geometry, delta time and shape factors"
            )
            for element_container in mesh.get_element_containers():
                element_container.update_geometry_parameters(mesh.nodes_handler)
                element_container.update_local_time_itervals(
                    mesh.nodes_handler,
                    simulation_parameters["simulation"]["safety_dt_factor"],
                    simulation_parameters["parameter"]["Re"],
                )
                element_container.update_shape_factors(mesh.nodes_handler)
                # output element properties to debug
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/b",
                    np.array([element.b for element in element_container.elements]),
                )
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/c",
                    np.array([element.c for element in element_container.elements]),
                )
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/dt",
                    np.array([element.dt for element in element_container.elements]),
                )
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/length",
                    np.array(
                        [element.length for element in element_container.elements]
                    ),
                )
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/area",
                    np.array([element.area for element in element_container.elements]),
                )
                output_manager.write_debug(
                    f"elements_data/{element_container.element_type}/volume",
                    np.array(
                        [element.volume for element in element_container.elements]
                    ),
                )

        self.logger.info("update old variable values with current value")
        mesh.nodes_handler.update_variables_old(variables_names)
        # solve the sequence of registered equations for each variable
        for equation in self.equations:
            self.logger.info(f"solving equation {equation.label}...")

            result, exit_status = equation.calculate_solution(
                mesh,
                self.assembler,
                domain_conditions,
                output_manager,
                self.logger,
                simulation_parameters,
                must_update_lhs,
            )
            # this could be done in parallel
            for variable in equation.solved_variables:
                solver_report = exit_status[variable]
                mesh.nodes_handler.update_variable_values(variable, result[variable])
                if not solver_report.success:
                    return IterationReport(
                        False,
                        True,
                        f"An issue detected in equation {equation.label} for variable {variable}\n"
                        + solver_report.status_message.value,
                    )

        mesh.nodes_handler.move_nodes()
        return check_convergence(
            mesh.nodes_handler, variables_names, simulation_parameters
        )
