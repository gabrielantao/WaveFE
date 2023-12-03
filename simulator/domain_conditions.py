from pathlib import Path
from dataclasses import dataclass
from enum import Enum, auto

import tomllib
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
        self.setup_default_initial_conditions(default_initial_values)
        self.setup_user_defined_conditions(mesh)

    def validate_conditions_data(self):
        # TODO: do a logical validation here to ensure :
        # - all group names are valid names
        # - all variables are valid variable names (just alert if not)
        # - valid condition type number
        # - alert duplicated conditions and pop from imported data
        # - break if there are two conditions with same (named group + variable + condition type)
        # message ambiguous or duplicated
        pass

    def setup_default_initial_conditions(self, default_initial_values):
        # TODO: it should load the default initial conditions set for this model
        # as a dict inside the class for this model
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

    def setup_user_defined_conditions(self, mesh):
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
                    condition_type = condition_data["condition_type"]
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
