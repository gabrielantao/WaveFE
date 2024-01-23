import numpy as np

from simulator.cbs_models.report_result import IterationReport, IterationStatusMessage


def check_convergence(
    nodes_handler, variables_names, simulation_parameters
) -> IterationReport:
    """Do the calculations to check if the current step converged"""
    relative_tolerance = simulation_parameters["simulation"]["tolerance_relative"]
    absolute_tolerance = simulation_parameters["simulation"]["tolerance_absolute"]
    for variable in variables_names:
        converged = np.allclose(
            nodes_handler.get_variable_values(variable),
            nodes_handler.get_variable_old_values(variable),
            rtol=relative_tolerance[variable],
            atol=absolute_tolerance[variable],
        )
        if not converged:
            return IterationReport(False, False, IterationStatusMessage.NORMAL)
    return IterationReport(True, True, IterationStatusMessage.CONVERGED)
