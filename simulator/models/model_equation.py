from simulator.assembler import Assembler, EquationSide
from simulator.element import ElementType


class ModelEquation:
    EQUATION_NAMES = []

    def __init__(self, equation_name, solved_variables, assembled_elements, assembler):
        # check if there are duplicated names for the equations
        if equation_name in EQUATION_NAMES:
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

    @property
    def total_solved_variables(self):
        """Get the total number of solved variables for this equation"""
        return len(self.solved_variables)

    def register_assembled_element(self, element_type: ElementType, lhs, rhs) -> None:
        # register function for left-hand side of equation 2
        assembler.register_function(
            equation_name,
            EquationSide.LHS.value,
            element_type.value,
            assemble_mass_lumped_lhs,
        )

    def assemble(self, mesh, assembler, simulation_parameters) -> None:
        """Set the assembled LHS and RHS of the model equation"""
        # TODO: only reasemble for LHS if something changed in the mesh values will improve performance
        self.lhs = assembler.assemble_lhs(self.label, mesh, simulation_parameters)
        self.rhs = assembler.assemble_rhs(self.label, mesh, simulation_parameters)

    def apply_conditions(self, domain_conditions, variable_name) -> None:
        """Apply the the boundary conditions for assembled LHS and RHS"""
        # TODO: only apply this condition for LHS if something changed in the mesh values will improve performance
        (
            self.lhs_condition_applied,
            self.rhs_condition_applied,
        ) = domain_conditions.get_equation_with_boundary_condition(
            self.lhs,
            self.rhs[:, i],
            variable_name,
        )

    def solve(
        self,
        nodes_handler,
        simulation_parameters,
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

    def calculate_solution(
        self, mesh, assembler, domain_conditions, simulation_parameters
    ):
        """Compute a solution for the current asssembled equation"""
        result = {}
        exit_status = {}
        # TODO: this could be done in parallel
        for variable_name in self.total_solved_variables:
            self.assemble(mesh, assembler, simulation_parameters)
            self.apply_conditions(domain_conditions, variable_name)
            result, exit_code = self.solve(
                mesh.nodes_handler, simulation_parameters, variable_name
            )
            result[variable_name] = result
            exit_status[variable_name] = exit_code
        return result, exit_status
