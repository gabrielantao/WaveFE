from abc import ABC, abstractmethod
from simulator.assembler import Assembler
from simulator.models.report_result import SolverStatusMessage, SolverReport


class AbstractCBSModel(ABC):
    """
    An abstract class to hold the steps of the model that must be solved.
    The models could be e.g. CBS semi-implicit, explicit, CBS with heat transfer, etc.
    The user of this method should register all
    """

    def __init__(self, parameters: dict[str, Any]):
        self._setup(parameters)

    @abstractmethod
    def get_default_initial_values(self, dimensions):
        """This return the initial values that must used for the variables"""
        pass

    @abstractmethod
    def _setup(self):
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

    def get_iteration_solver_report(self, exit_status) -> SolverReport:
        """Return the iteration status and the message to show the user"""
        if exit_status == 0:
            return SolverReport(success=True, message=SolverStatusMessage.SUCCESS)
        elif exit_status > 0:
            return SolverReport(
                success=False, message=SolverStatusMessage.SOLVER_MAX_ITER_REACHED
            )
        elif exit_status < 0:
            return SolverReport(success=False, message=SolverStatusMessage.ILEGAL_INPUT)