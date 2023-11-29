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

    def __init__(self, boundary_conditions_filepath: Path, mesh: Mesh):
        with open(boundary_conditions_filepath, "rb") as f:
            self.conditions_data = tomllib.load(f)
        self.initial_conditions = {}
        self.boundary_conditions = {}
        self.validate_conditions_data()
        self.setup_conditions(mesh)

    def validate_conditions_data(self):
        # TODO: do a logical validation here to ensure :
        # all group names are valid names,
        # all variables are valid variable names (just alert if not)
        # valid condition type number
        # alert duplicated conditions and pop from imported data
        # break if there are two conditions with same group and variable and condition type and different values (ambiguous)
        pass

    def setup_conditions(self, mesh):
        """
        Setup the set of indices and values for each variable and condition type configured
        in the condition files loaded.
        """
        self.initial_conditions = {
            (
                initial_condition_data["variable_name"],
                initial_condition_data["condition_type"],
            ): Conditions([], [])
            for initial_condition_data in self.conditions_data["initial"]
        }
        # create initial conditions and
        for node_id in range(mesh.nodes_handler.total_nodes):
            for condition_data in self.conditions_data["initial"]:
                group_number = mesh.named_groups[condition_data["group_name"]]
                if mesh.nodes_handler[node_id].named_group == group_number:
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
                group_number = mesh.named_groups[condition_data["group_name"]]
                if mesh.nodes_handler[node_id].named_group == group_number:
                    variable_name = condition_data["variable_name"]
                    condition_type = condition_data["condition_type"]
                    value = condition_data["value"]
                    self.initial_conditions[
                        (variable_name, condition_type)
                    ].indices.append(node_id)
                    self.initial_conditions[
                        (variable_name, condition_type)
                    ].values.append(value)
