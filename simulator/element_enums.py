from enum import Enum, auto

class GroupType(Enum):
    """
    Enum to hold data for type of the group
    physical and geometrical groups are free to use inside the model
    (e.g. to define boundary to calculate some properties such as drag and lift in surface)
    named group is used to define boundary conditions
    """

    GEOMETRICAL = auto()
    PHYSICAL = auto()
    NAMED = auto()


class ElementType(Enum):
    """All types of element supported for now"""

    NODE = auto()
    SEGMENT = auto()
    TRIANGLE = auto()
    QUADRILATERAL = auto()
    # TODO: complete this enum when implement other element types
    # ...