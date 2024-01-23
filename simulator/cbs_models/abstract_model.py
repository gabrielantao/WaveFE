from abc import ABC, abstractmethod
from pathlib import Path
import numpy as np

from simulator.assembler import Assembler


class AbstractCBSModel(ABC):
    """
    An abstract class to hold the steps of the model that must be solved.
    The models could be e.g. CBS semi-implicit, explicit, CBS with heat transfer, etc.
    The user of this method should register all
    """

    def __init__(self):
        self.VARIABLES = []
        self.DEFAULT_INITIAL_VALUES = {}

    @abstractmethod
    def get_default_initial_values(self, dimensions):
        """This return the initial values that must used for the variables"""
        pass

    @abstractmethod
    def setup(self) -> None:
        """
        This function register functions and the number of solved variables for each equation
        of this model
        """
        pass

    @abstractmethod
    def run_iteration(self, mesh, domain_conditions, parameters) -> None:
        """
        This function runs a single iteration for the model.
        The class that implements this CBS model should define all steps to solve interest variables
        inside this method.
        This method should not save results (only logs and debuging data)
        """
        pass

    def apply_initial_default_values(self, nodes_handler):
        """Apply the initial default values for the current model"""
        for node in nodes_handler.nodes:
            for variable_name, value in self.DEFAULT_INITIAL_VALUES.items():
                node.variables[variable_name] = value
