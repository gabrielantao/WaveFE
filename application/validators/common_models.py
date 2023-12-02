from pydantic import constr, confloat, NonNegativeFloat, NonNegativeInt
from typing import Literal

AliasName = constr(pattern=r"^[a-zA-Z0-9_]+$")
VariableName = constr(pattern=r"^[a-zA-Z0-9_]+$")
AbsoluteTolerance = NonNegativeFloat
RelativeTolerance = confloat(ge=0.0, le=1.0)
DeltaTimeFactor = confloat(gt=0.0, le=1.0)
GroupNumber = NonNegativeInt
ConditionType = NonNegativeInt
GroupType = Literal["physical", "geometrical"]
