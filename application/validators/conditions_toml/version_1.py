"""Validators for mesh data version 1"""

from typing import List, Dict, Optional
from pydantic import BaseModel

from application.validators.common_models import (
    UnknownName,
    ConditionType,
)


class SectionGeneral(BaseModel):
    """
    [general]

    This section just have some general data for this file.
    """

    version: int
    description: Optional[str] = ""


class Initial(BaseModel):
    """
    [[initial]]

    This section has all the descriptions for initial conditions.
    """

    group_name: str
    unknown: UnknownName
    value: float
    description: Optional[str] = ""


class Boundary(BaseModel):
    """
    [[boundary]]

    A boundary condition entry
    """

    group_name: str
    condition_type: ConditionType
    unknown: UnknownName
    value: float
    description: Optional[str] = ""


class Validator(BaseModel):
    """
    Validator for conditions
    """

    general: SectionGeneral
    initial: Optional[List[Initial]] = []
    boundary: Optional[List[Boundary]] = []
