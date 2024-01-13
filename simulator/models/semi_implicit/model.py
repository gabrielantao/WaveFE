from typing import Any
from pathlib import Path
import logging
from scipy import sparse

from simulator.models.abstract_model import AbstractCBSModel
from simulator.assembler import Assembler, EquationSide
from simulator.assembled_equation import AssembledEquation
from simulator.element import ElementType
from simulator.models.semi_implicit.assembing_elements import (
    assemble_mass_lumped_lhs,
    assemble_mass_lhs,
    assemble_stiffness_lhs,
    assemble_element_rhs_step_1,
    assemble_element_rhs_step_2,
    assemble_element_rhs_step_3,
)
from simulator.models.report_result import IterationReport, IterationStatusMessage
from simulator.models.model_equation import ModelEquation


class CBSSemiImplicit(AbstractCBSModel):
    """A CBS semi-implicit basic model"""

    VARIABLES = ["u_1", "u_2", "u_3", "p"]
    DEFAULT_INITIAL_VALUES = {"u_1": 0.0, "u_2": 0.0, "u_3": 0.0, "p": 0.0001}

    def __init__(self):
        pass

    def setup(self, logger, simulation_parameters: dict[str, Any]):
        """Setup functions used for assembling process"""

        # setup the logger
        self.logger = logger
        self.logger.info(f"Doing the model setup.")

        # setup an assembler instance for this model
        self.assembler = Assembler()

        # check if it should use lumped mass to solve the problem
        use_lumped_mass = not simulation_parameters["simulation"]["transient"]

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

    def get_variables(self):
        """Get the list of model variables"""
        return self.VARIABLES

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
        output_manager,
        simulation_parameters,
        step_number: int,
    ):
        """Run the three steps of semi-implicit model"""
        # status variables
        success = False
        stop_simulation = False
        status_message = StatusMessage.NORMAL

        # setup old variables values with current values of the variables
        mesh.nodes_handler.update_variables_old(self.VARIABLES)
        must_update_lhs = mesh.nodes_handler.moved
        # solve the sequence of registered equations for each variable
        for equation in self.equations:
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
                solver_report = self.get_iteration_solver_report(exit_status[variable])
                mesh.nodes_handler.update_variable_values(variable, result[variable])
                if not solver_report.success:
                    return IterationReport(
                        False,
                        True,
                        f"An issue detected in equation {equation.label} for variable {variable}\n"
                        + solver_report.status_message.value,
                    )

        mesh.nodes_handler.move_nodes()
        return self.check_convergence(mesh.nodes_handler, simulation_parameters)
