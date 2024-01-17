# Here a instance of a class that call the simulation, save debug data and make the regression
import glob

from application.constants import PATH_CBS_MODELS
from simulator.case_regression import CaseRegressionTest
from simulator.cbs_models.models_register import AVAILABLE_MODELS


# TODO: this should be done without pytest
def test_run_regression(shared_datadir):
    model = "*"
    cases = "*"
    for case_path in PATH_CBS_MODELS.glob(f"models/{model}/cases/{cases}"):
        # TODO: save the results in cache folder do not copy result to its own directory
        case_regression = CaseRegressionTest(case_path)
        case_regression.case.run()
