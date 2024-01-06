class ModelEquation:
    def __init__(self, equation_name, solved_variables):
        self.label = equation_name
        self.solved_variables = solved_variables

    @property
    def total_solved_variables(self):
        """Get the total number of solved variables for this equation"""
        return len(self.solved_variables)

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

    def solve(self, variable_name, simulation_parameters):
        """Solve the equation using the parameters defined"""
        # starting guess for the solution with variables of current time
        x0 = mesh.nodes_handler.get_variable_values(variable_name)
        # TODO: put the maxiter and tolerances here from parameters values
        return sparse.linalg.cg(lhs_condition_applied, rhs_condition_applied, x0)

    def get_solution(self, mesh, assembler, domain_conditions, simulation_parameters):
        """Compute a solution for the current asssembled equation"""
        result = {}
        exit_status = {}
        # TODO: this could be done in parallel
        for variable_name in self.total_solved_variables:
            self.assemble(mesh, assembler, simulation_parameters)
            self.apply_conditions(domain_conditions, variable_name)
            result, exit_code = self.solve(variable_name, simulation_parameters)
            result[variable_name] = result
            exit_status[variable_name] = exit_code
        return result, exit_status
