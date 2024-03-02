"""Validators for mesh data version 1"""

from typing import List, Literal, Dict, Optional
from pathlib import Path

from pydantic import (
    BaseModel,
    PositiveInt,
    conint,
)

from application.validators.common_models import (
    AliasName,
    UnknownName,
    AbsoluteTolerance,
    RelativeTolerance,
    DeltaTimeFactor,
)


class SectionGeneral(BaseModel):
    """[general]"""

    version: int
    title: str
    alias: AliasName
    description: Optional[str] = ""

    class Config:
        extra = "forbid"


class SectionSimulation(BaseModel):
    """[simulation]"""

    model: str
    steps_limit: PositiveInt
    transient: bool
    safety_dt_factor: DeltaTimeFactor
    tolerance_absolute: Optional[Dict[str, AbsoluteTolerance]]
    tolerance_relative: Optional[Dict[str, RelativeTolerance]]

    class Config:
        extra = "forbid"


class SectionMesh(BaseModel):
    """[mesh]"""

    filename: Path
    interpolation_order: conint(ge=1, le=3)


class SectionSolver(BaseModel):
    """[solver]"""

    name: Literal["Conjugate Gradient"]
    preconditioner: Literal["Jacobi"]
    steps_limit: PositiveInt
    tolerance_absolute: AbsoluteTolerance
    tolerance_relative: RelativeTolerance


class SectionOutput(BaseModel):
    """[output]"""

    frequency: PositiveInt
    save_result: bool
    save_numeric: bool
    save_debug: bool
    unknowns: List[UnknownName]


class Validator(BaseModel):
    """Model to validate simulation.toml input file"""

    general: SectionGeneral
    simulation: SectionSimulation
    mesh: SectionMesh
    parameter: Dict[str, float]
    solver: SectionSolver
    output: SectionOutput
