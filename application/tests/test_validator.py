from pathlib import Path

import pytest
from pytest_regressions.data_regression import DataRegressionFixture

from application.constants import PATH_CASES
from application.validator import (
    validate_input_file,
    InputFileType,
)


def test_validation_simulation_toml(
    shared_datadir: Path, data_regression: DataRegressionFixture
):
    data = validate_input_file(
        shared_datadir / "input_validation" / "simulation.toml",
        InputFileType.SIMULATION,
    )
    assert len(data) > 0
    # this is done just to avoid the PosixPath
    data["mesh"]["filename"] = str(data["mesh"]["filename"])
    data_regression.check(
        data, basename=f"simulation_toml_v{data['general']['version']}"
    )


def test_validation_domain_condition_toml(
    shared_datadir: Path, data_regression: DataRegressionFixture
):
    data = validate_input_file(
        shared_datadir / "input_validation" / "conditions.toml",
        InputFileType.DOMAIN_CONDITIONS,
    )
    assert len(data) > 0
    data_regression.check(
        data, basename=f"domain_conditions_toml_v{data['general']['version']}"
    )
