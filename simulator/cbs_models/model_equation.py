from numba import typed, types
from scipy import sparse

from simulator.assembler import Assembler, EquationSide
from simulator.element import ElementType
from simulator.cbs_models.report_result import SolverStatusMessage, SolverReport


class ModelEquation:
    EQUATION_NAMES = []

    def __init__(self, equation_name, solved_variables, assembled_elements, assembler):
        # check if there are duplicated names for the equations
        if equation_name in self.EQUATION_NAMES:
            raise ValueError(
                f"Equation name {equation_name} is duplicated, check the setup method for this current model to fix this."
            )
        self.EQUATION_NAMES.append(equation_name)
        self.label = equation_name
        self.solved_variables = solved_variables
        # register how many variables is solved in the equation
        assembler.register_total_variables_assembled(
            equation_name, self.total_solved_variables
        )
        # register the elemental assembler functions for LHS and RHS of the equation
        for element_registry in assembled_elements:
            assembler.register_function(
                equation_name,
                EquationSide.LHS,
                element_registry["element_type"],
                element_registry["lhs"],
            )
            assembler.register_function(
                equation_name,
                EquationSide.RHS,
                element_registry["element_type"],
                element_registry["rhs"],
            )
        # attributes to hold last assembled LHS andRHS
        self.lhs_assembled = None
        self.rhs_assembled = None
        # attributes assembled+boundary applied LHS
        self.lhs_condition_applied = {}
        self.lhs_preconditioners = {}

    @property
    def total_solved_variables(self):
        """Get the total number of solved variables for this equation"""
        return len(self.solved_variables)

    def solve(
        self,
        nodes_handler,
        simulation_parameters,
        lhs_condition_applied,
        rhs_condition_applied,
        variable_name,
    ):
        """Solve the equation using the parameters defined"""
        # TODO: name and the preconditioner here
        return sparse.linalg.cg(
            lhs_condition_applied,
            rhs_condition_applied,
            x0=nodes_handler.get_variable_values(variable_name),
            tol=simulation_parameters["solver"]["tolerance_relative"],
            maxiter=simulation_parameters["solver"]["steps_limit"],
            # atol=simulation_parameters["solver"]["tolerance_absolute"],
        )

    def get_iteration_solver_report(self, exit_status) -> SolverReport:
        """Return the iteration status and the message to show the user"""
        if exit_status == 0:
            return SolverReport(
                success=True, status_message=SolverStatusMessage.SUCCESS
            )
        elif exit_status > 0:
            return SolverReport(
                success=False,
                status_message=SolverStatusMessage.SOLVER_MAX_ITER_REACHED,
            )
        elif exit_status < 0:
            return SolverReport(
                success=False, status_message=SolverStatusMessage.ILEGAL_INPUT
            )

    def calculate_solution(
        self,
        mesh,
        assembler,
        domain_conditions,
        output_manager,
        logger,
        simulation_parameters,
        must_update_lhs=True,
        must_update_rhs=True,
    ):
        """Compute a solution for the current asssembled equation"""
        output_results = {}
        exit_status = {}
        # get only simulation related parameters from input file data
        parameters = typed.Dict.empty(types.unicode_type, types.float64)
        for parameter_name, value in simulation_parameters["parameter"].items():
            parameters[parameter_name] = value

        # assemble and apply boundary conditions for LHS if needed
        if must_update_lhs:
            logger.info("updating LHS")
            self.lhs_assembled = assembler.assemble_lhs(self.label, mesh, parameters)

        # apply boundary conditions for RHS if needed
        if must_update_rhs:
            logger.info("updating RHS")
            self.rhs_assembled = assembler.assemble_rhs(self.label, mesh, parameters)

        output_manager.write_debug(f"{self.label}/lhs_assembled", self.lhs_assembled)
        output_manager.write_debug(f"{self.label}/rhs_assembled", self.rhs_assembled)
        # TODO: this could be done in parallel
        for variable_name in self.solved_variables:
            variable_id = self.solved_variables.index(variable_name)
            if must_update_lhs:
                logger.info("applying conditions to LHS")
                self.lhs_condition_applied[
                    variable_name
                ] = domain_conditions.get_lhs_with_boundary_condition(
                    self.lhs_assembled, variable_name
                )
                # TODO: update the preconditioner here
            if must_update_rhs:
                logger.info("applying conditions to RHS")
                # TODO: fix here and beyond
                rhs_condition_applied = (
                    domain_conditions.get_rhs_with_boundary_condition(
                        self.lhs_assembled,
                        self.rhs_assembled[:, variable_id],
                        variable_name,
                    )
                )
            output_manager.write_debug(
                f"{self.label}/{variable_name}/lhs_condition_applied",
                self.lhs_condition_applied[variable_name],
            )
            output_manager.write_debug(
                f"{self.label}/{variable_name}/rhs_condition_applied",
                rhs_condition_applied,
            )

            # solve the current equation
            logger.info(
                f"solving the equation {self.label} for variable {variable_name}..."
            )
            current_result, exit_code = self.solve(
                mesh.nodes_handler,
                simulation_parameters,
                self.lhs_condition_applied[variable_name],
                rhs_condition_applied,
                variable_name,
            )
            output_results[variable_name] = current_result
            exit_status[variable_name] = self.get_iteration_solver_report(exit_code)
        return output_results, exit_status
