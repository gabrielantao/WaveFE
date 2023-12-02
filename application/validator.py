"""This module has all validation classes."""
import importlib
from pathlib import Path
from typing import Any
import logging

from enum import StrEnum
import toml

from pydantic import ValidationError, BaseModel


class InputFileType(StrEnum):
    """This class just holds names for input files to be loaded by the validator function"""

    SIMULATION = "simulation_toml"
    DOMAIN_CONDITIONS = "conditions_toml"
    # TODO: include others here


def validate_input_file(filepath: Path, file_type: InputFileType) -> dict[str, Any]:
    """
    Validate a input file depending on file extension
    it returns the valid dictionary and status (success True)
    """
    content = toml.load(filepath)
    # get version from the file itself
    version = content["general"]["version"]
    module = importlib.import_module(
        f"application.validators.{file_type.value}.version_{version}"
    )
    try:
        return module.Validator(**content).dict(exclude_unset=True)
    except ValidationError as error:
        logging.error("invalid input file: %s\n%s", filepath, error)
        exit()
