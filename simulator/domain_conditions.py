from pathlib import Path
from dataclasses import dataclass
from enum import Enum, auto

import tomllib
import numpy as np
from simulator.mesh import Mesh


class ConditionType(Enum):
    """
    First type condtions specifies the values of variable applied at the boundary (AKA Dirichlet)
    Second type condtions specifies the values of the derivative applied at the boundary of the domain. (AKA  Neumann condition)
    """

    FIRST = auto()
    SECOND = auto()
    # TODO: maybe implement in the future the other conditions (Cauchy and Robin) with combination of these two others


# TODO: check if this could be better a jitclass
@dataclass
class Conditions:
    """It holds the conditions (initial or boundary) to be applied to vectors/matrices before solving process"""

    indices: list
    values: list


# TODO: check if this could be better a jitclass
class DomainConditions:
    """
    This holds data related to initial and boundary conditions
    First type condtions here are Dirichlet conditions (prescribed values)
    Second type condtions here are Newmann conditions (prescribed derivative values)
    """

    def __init__(
        self,
        conditions_filepath: Path,
        mesh: Mesh,
        default_initial_values: dict[str, float],
    ):
        with open(conditions_filepath, "rb") as f:
            self.conditions_data = tomllib.load(f)
        self.validate_conditions_data()
        # create the conditions
        self.initial_conditions = {
            (
                condition_data["variable_name"],
                condition_data["condition_type"],
            ): Conditions([], [])
            for condition_data in self.conditions_data["initial"]
        }
        self.boundary_conditions = {
            (
                condition_data["variable_name"],
                condition_data["condition_type"],
            ): Conditions([], [])
            for condition_data in self.conditions_data["boundary"]
        }
        self._setup_user_defined_conditions(mesh)

    def validate_conditions_data(self):
        # TODO: do a logical validation here to ensure :
        # - all group names are valid names
        # - all variables are valid variable names (just alert if not)
        # - valid condition type number (raise by now if is not first type not implemented yet)
        # - alert duplicated conditions and pop from imported data
        # - break if there are two conditions with same (named group + variable + condition type)
        #   message ambiguous or duplicated
        # - for now only allow first type condition (value conition) for initial values
        #   change this for validation process
        pass

    def _setup_user_defined_conditions(self, mesh):
        """
        Setup the set of indices and values for each variable and condition type configured
        in the condition files loaded.
        """
        # setup initial and boundary conditions from the conditions data file
        for node_id in range(mesh.nodes_handler.total_nodes):
            for condition_data in self.conditions_data["initial"]:
                # if the group name is empty in the input file then define it always the condition
                if len(condition_data["group_name"]) == 0:
                    node_in_group = True
                else:
                    group_number = mesh.named_groups[condition_data["group_name"]]
                    node_in_group = (
                        mesh.nodes_handler.nodes[node_id].named_group == group_number
                    )
                if node_in_group:
                    variable_name = condition_data["variable_name"]
                    # only apply first condition type as initial values
                    condition_type = ConditionType.FIRST.value
                    value = condition_data["value"]
                    self.initial_conditions[
                        (variable_name, condition_type)
                    ].indices.append(node_id)
                    self.initial_conditions[
                        (variable_name, condition_type)
                    ].values.append(value)
            for condition_data in self.conditions_data["boundary"]:
                # if the group name is empty in the input file then define it always the condition
                if len(condition_data["group_name"]) == 0:
                    node_in_group = True
                else:
                    group_number = mesh.named_groups[condition_data["group_name"]]
                    node_in_group = (
                        mesh.nodes_handler.nodes[node_id].named_group == group_number
                    )
                if node_in_group:
                    variable_name = condition_data["variable_name"]
                    condition_type = condition_data["condition_type"]
                    value = condition_data["value"]
                    self.boundary_conditions[
                        (variable_name, condition_type)
                    ].indices.append(node_id)
                    self.boundary_conditions[
                        (variable_name, condition_type)
                    ].values.append(value)

    def apply_initial_conditions(self, nodes_handler):
        """Apply user defined initial values for the variables"""
        # apply initial condition values for the nodes
        for variable_condition_type, condition in self.initial_conditions.items():
            variable_name, _ = variable_condition_type
            for index, value in zip(condition.indices, condition.values):
                nodes_handler.nodes[index].variables[variable_name] = value
        # apply boundary values (first type condition type) for the nodes
        for variable_condition_type, condition in self.boundary_conditions.items():
            variable_name, condition_type = variable_condition_type
            if condition_type == ConditionType.FIRST.value:
                for index, value in zip(condition.indices, condition.values):
                    nodes_handler.nodes[index].variables[variable_name] = value

    def get_lhs_with_boundary_condition(self, lhs, variable_name):
        """Return the LHS of equation with boundary conditions applied"""
        lhs_boundary_applied = lhs.copy()
        for index in self.boundary_conditions[
            (variable_name, ConditionType.FIRST.value)
        ].indices:
            lhs_boundary_applied[:, index] = 0.0
            lhs_boundary_applied[index, :] = 0.0
            lhs_boundary_applied[index, index] = 1.0
        lhs_boundary_applied.eliminate_zeros()
        # TODO: check how to apply condition for the other type here
        return lhs_boundary_applied

    def get_rhs_with_boundary_condition(self, lhs, rhs, variable_name):
        """
        Return the RHS of equation with boundary conditions applied
        NOTE: this function expect a one-dimension vector for RHS
        """
        # first condition application
        boundary_conditions = self.boundary_conditions[
            (variable_name, ConditionType.FIRST.value)
        ]
        offset_vector = self._calculate_rhs_offset_values(lhs, variable_name)
        rhs_boundary_applied = rhs + offset_vector
        rhs_boundary_applied[boundary_conditions.indices] = boundary_conditions.values
        # TODO: do the calculations for the other condition_types
        return rhs_boundary_applied

    def _calculate_rhs_offset_values(self, lhs, variable_name: str):
        """Calculate the vector to be added to rhs vector due boundary condition application"""
        boundary_conditions = self.boundary_conditions[
            (variable_name, ConditionType.FIRST.value)
        ]
        total_rows = lhs.shape[0]
        offset = np.zeros((total_rows, 1), dtype=np.float64)
        # accumulate column vectors in sparse matrix with boundary indices
        for column_id, value in zip(
            boundary_conditions.indices, boundary_conditions.values
        ):
            offset -= lhs[:, [column_id]] * value
        # TODO: apply conditions of second type here ...
        # ensure zeros in offset vector in positions where boundary are applied
        # this is needed to not mess values when other t
        offset[boundary_conditions.indices] = 0.0
        return offset.reshape(total_rows)

    def apply_first_type_condition(self, variable_name, variable_values):
        boundary_conditions = self.boundary_conditions[
            (variable_name, ConditionType.FIRST.value)
        ]
        variable_values[boundary_conditions.indices] = boundary_conditions.values
