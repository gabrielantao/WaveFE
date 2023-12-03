from abc import ABC, abstractmethod
from simulator.assembler import Assembler


class AbstractCBSModel(ABC):
    """
    An abstract class to hold the steps of the model that must be solved.
    The models could be e.g. CBS semi-implicit, explicit, CBS with heat transfer, etc.
    The user of this method should register all
    """

    def __init__(self):
        # TODO: it should assert the velocities and pressure variables as u_1, u_2, u_3 and p
        pass

    @abstractmethod
    def get_default_initial_values(self, dimensions):
        """This return the initial values that must used for the variables"""
        pass

    @abstractmethod
    def setup_assembler(self, assembler: Assembler):
        """
        This function register functions and the number of solved variables for each equation
        of this model
        """
        pass

    @abstractmethod
    def run_iteration(self, mesh, domain_conditions, simulation_parameters):
        """
        This function runs a single iteration for the model.
        The class that implements this CBS model should define all steps to solve interest variables
        inside this method.
        This method should not save results (only logs and debuging data)
        """
        pass
