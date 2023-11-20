from abc import ABC, abstractmethod
from simulator.element import ElementType


class AbstractCBSModel(ABC):
    """
    An abstract class to hold the steps of the model that must be solved.
    The models could be e.g. CBS semi-implicit, explicit, CBS with heat transfer, etc.
    The user of this method should register all
    """

    # TODO: check if this __init__ is gonna work for abstract class
    def __init__(self, name, element_assembling_register):
        self.name = name
        self.element_assembler = element_assembling_register

    @abstractmethod
    def run_iteration(self, mesh, boundary_conditions, simulation_parameters):
        """
        This function runs a single iteration for the model.
        The class that implements this CBS model should define all steps to solve interest variables
        inside this method.
        This method should not save results (only logs and debuging data)
        """
        pass
