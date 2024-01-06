from dataclasses import dataclass
from numpy.typing import ArrayLine
from enum import StrEnum


class IterationStatusMessage(StrEnum):
    NORMAL = "Succeed iteraction step, it did not converged yet."
    CONVERGED = "The current iteraction CONVERGED."
    DIVERGED = "The current iteraction of the model running have DIVERGED!"


class SolverStatusMessage(StrEnum):
    SUCCESS = "Succeed iteraction step."
    SOLVER_MAX_ITER_REACHED = "The maximum number of iterations was reached for the solver (status > 0). (status < 0). See scipy.sparse.linalg.cg for more info. "
    ILEGAL_INPUT = "Ilegal input of the solver (status < 0). See scipy.sparse.linalg.cg for more info."


@dataclass
class IterationReport:
    """It holds data about the current iteration step of the model solved"""

    converged: bool
    stop_simulation: bool
    status_message: str


@dataclass
class SolverReport:
    """It holds data about the current iteration solver status"""

    success: bool
    status_message: str
