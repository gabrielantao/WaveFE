from typing import Any
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

    def __init__(self, parameters: dict[str, Any]):
        super().__init__(parameters)
        # TODO: it should assert the velocities and pressure variables as u_1, u_2, u_3 and p

    def _setup(self, parameters):
        """Setup functions used for assembling process"""
        # setup an assembler instance for this model
        self.assembler = Assembler()

        #################################
        ### CREATE EQUATION OF STEP 1 ###
        #################################
        equation_1 = ModelEquation(
            "step 1", [f"u_{i + 1}" for i in range(self.parameters["dimension"])]
        )
        # register how many variables is solved in equation 1
        # dimension represents how many velocity direction will be solved
        self.assembler.register_total_variables_assembled(
            equation_1.label, equation_1.total_solved_variables
        )
        # register function for left-hand side of equation 1
        # TODO: think better here, put an if to decide which step 1 LHS should be registered
        # if parameters['lumped']:
        #     self.assembler.register_function(
        #         "step 1 mass_transient",
        #         EquationSide.LHS.value,
        #         ElementType.TRIANGLE.value,
        #         assemble_mass_lhs,
        #     )
        # for right-hand side of equation 1 (lumped mass matrix)
        self.assembler.register_function(
            equation_1.label,
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lumped_lhs,
        )
        # for right-hand side of equation 1
        self.assembler.register_function(
            equation_1.label,
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_1,
        )

        #################################
        ### CREATE EQUATION OF STEP 2 ###
        #################################
        equation_2 = ModelEquation("step 2", "p")
        # register how many variables is solved in equation 2
        # step 2 only have pressure variable to be solved
        self.assembler.register_total_variables_assembled(
            equation_2.label, equation_2.total_solved_variables
        )
        # register function for left-hand side of equation 2
        self.assembler.register_function(
            equation_2.label,
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_stiffness_lhs,
        )
        # register function for right-hand side of equation 2
        self.assembler.register_function(
            equation_2.label,
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_2,
        )

        #################################
        ### CREATE EQUATION OF STEP 3 ###
        #################################
        equation_3 = ModelEquation(
            "step 3", [f"u_{i + 1}" for i in range(self.parameters["dimension"])]
        )
        # register how many variables is solved in equation 3
        # dimension represents how many velocity direction will be solved
        self.assembler.register_total_variables_assembled(
            equation_3.label, equation_3.total_solved_variables
        )
        # dimension represents how many velocity direction will be solved
        # register function for left-hand side of equation 3
        # TODO: think better here, put an if to decide which step 1 LHS should be registered
        # if parameters['lumped']:
        #     self.assembler.register_function(
        #         "step 3 mass_transient",
        #         EquationSide.LHS.value,
        #         ElementType.TRIANGLE.value,
        #         assemble_mass_lhs,
        #     )
        # for right-hand side of equation 3 (lumped mass matrix)
        self.assembler.register_function(
            equation_3.label,
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lumped_lhs,
        )
        self.assembler.register_function(
            equation_3.label,
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_3,
        )

        # create the list of equations
        self.equations = [equation_1, equation_2, equation_3]

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

    def run_iteration(self, mesh, domain_conditions, simulation_parameters):
        """Run the three steps of semi-implicit model"""
        # status variables
        success = False
        stop_simulation = False
        status_message = StatusMessage.NORMAL

        # setup old variables values with current values of the variables
        mesh.nodes_handler.update_variables_old(self.VARIABLES)

        ### CBS solve step 1 (intermediate velocities) ###
        result, exit_status = equation_1.get_solution(
            mesh, self.assembler, domain_conditions, simulation_parameters
        )
        for variable in equation_1.solved_variables:
            solver_report = self.get_iteration_solver_report(exit_status[variable])
            if not solver_report.success:
                return IterationReport(
                    False,
                    True,
                    f"Issue detected for variable: {variable}\n"
                    + solver_report.status_message.value,
                )
            mesh.nodes_handler.update_variable_values(variable, result[variable])

        ### CBS solve step 2 (pressures) ###
        result, exit_status = equation_2.get_solution(
            mesh, self.assembler, domain_conditions, simulation_parameters
        )
        solver_report = self.get_iteration_solver_report(exit_status[variable])
        if not solver_report.success:
            return IterationReport(
                False,
                True,
                f"Issue detected for variable: {variable}\n"
                + solver_report.status_message.value,
            )
        mesh.nodes_handler.update_variable_values(variable, result[variable])

        ### CBS solve step 3 (real velocities) ###
        result, exit_status = equation_3.get_solution(
            mesh, self.assembler, domain_conditions, simulation_parameters
        )
        for variable in equation_3.solved_variables:
            solver_report = self.get_iteration_solver_report(exit_status[variable])
            if not solver_report.success:
                return IterationReport(
                    False,
                    True,
                    f"Issue detected for variable: {variable}\n"
                    + solver_report.status_message.value,
                )
            mesh.nodes_handler.update_variable_values(variable, result[variable])

        # TODO: check convergence and check if its diverging (if so, then break simulation)

        return self.check_convergence()

        def check_convergence(self) -> IterationReport:
            """Do the calculations to check if the current step converged"""
            pass
