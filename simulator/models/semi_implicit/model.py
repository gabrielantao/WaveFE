from typing import Any
from simulator.abstract_model import AbstractCBSModel
from simulator.assembler import Assembler, EquationSide
from simulator.element import ElementType
from simulator.models.semi_implicit.assembing_elements import (
    assemble_mass_lumped_lhs,
    assemble_mass_lhs,
    assemble_stiffness_lhs,
    assemble_element_rhs_step_1,
    assemble_element_rhs_step_2,
    assemble_element_rhs_step_3,
)


class CBSSemiImplicit(AbstractCBSModel):
    """A CBS semi-implicit basic model"""

    VARIABLES = ["u_1", "u_2", "u_3", "p"]
    DEFAULT_INITIAL_VALUES = {"u_1": 0.0, "u_2": 0.0, "u_3": 0.0, "p": 0.0001}

    def __init__(self):
        pass

    def setup_assembler(self, assembler: Assembler, parameters: dict[str, Any]):
        """Setup functions used for assembling process"""
        # register functions for left-hand side of solved equations
        assembler.register_function(
            "step 1 mass_lumped",
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lumped_lhs,
        )
        assembler.register_function(
            "step 1 mass_transient",
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lhs,
        )
        assembler.register_function(
            "step 2 stiffness",
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_stiffness_lhs,
        )
        assembler.register_function(
            "step 3 mass_lumped",
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lumped_lhs,
        )
        assembler.register_function(
            "step 3 mass_transient",
            EquationSide.LHS.value,
            ElementType.TRIANGLE.value,
            assemble_mass_lhs,
        )
        # register functions to be used to assemble the elements
        # for right-side of each equation solved by the model
        assembler.register_function(
            "step 1",
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_1,
        )
        assembler.register_function(
            "step 2",
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_2,
        )
        assembler.register_function(
            "step 3",
            EquationSide.RHS.value,
            ElementType.TRIANGLE.value,
            assemble_element_rhs_step_3,
        )
        # register how many variables is solved by each equation
        # dimension represents how many velocity direction will be solved
        # step 2 only have pressure variable to be solved
        assembler.register_total_variables_assembled("step 1", parameters["dimension"])
        assembler.register_total_variables_assembled("step 2", 1)
        assembler.register_total_variables_assembled("step 3", parameters["dimension"])

    def get_variables(self):
        """Get the list of model variables"""
        return self.VARIABLES

    def get_default_initial_values(self):
        """Get the initial values for all variables"""
        # TODO: fix this here
        dimension = self.mesh.nodes_handler.dimensions
        default_initial_values = self.DEFAULT_INITIAL_VALUES.copy()
        match dimension:
            case 1:
                default_initial_values.pop("u_2")
                default_initial_values.pop("u_3")
                return default_initial_values
            case 2:
                default_initial_values.pop("u_3")
                return default_initial_values
            case 3:
                return default_initial_values

    def run_iteration(self, mesh, boundary_conditions, simulation_parameters):
        """Run the three steps of semi-implicit model"""
        # TODO:
        # assemble equation 1
        # apply boundary conditions
        # update the velocities values

        # assemble equation 2
        # apply boundary conditions
        # solve equation 2
        # update the pressure values

        # assemble equation 3
        # apply boundary conditions
        # solve equation 3
        # update the velocities values
        pass
