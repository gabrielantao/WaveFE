import numpy as np
from numba import njit, typed
from numba.experimental import jitclass

from simulator.element_enums import ElementType


@njit
def calculate_length_segment(nodes):
    """Calculate length for an element of type segment"""
    # get only the firest two nodes, they are the ending nodes
    return np.linalg.norm(nodes[0].position - nodes[1].position)


@njit
def calculate_area_triangle(nodes):
    """
    Calculate area for an triangle
    It only calculates area for elements in 2 dimension mesh
    """
    return 0.5 * np.abs(
        (nodes[1].position[0] - nodes[0].position[0])
        * (nodes[2].position[1] - nodes[0].position[1])
        - (nodes[2].position[0] - nodes[0].position[0])
        * (nodes[1].position[1] - nodes[0].position[1])
    )


@njit
def calculate_area_quadrilateral(nodes):
    """
    Calculate area for a quadrilateral
    It only calculates area for elements in 2 dimension mesh
    """
    diagonal_1 = calculate_length_segment(typed.List([nodes[0], nodes[2]]))
    diagonal_2 = calculate_length_segment(typed.List([nodes[1], nodes[3]]))
    return 0.5 * diagonal_1 * diagonal_2


# TODO: implement functions to calculate volume of 3D elements here...


@njit
def calculate_specific_size_triangle(element_area, nodes):
    """
    Calculate the specific size parameter for the triangle.
    This is used in context of CBS to calculate local time interval to be used
    for an element when the simulator runs steady state case.
    """
    max_edge_length = np.max(
        np.array(
            [
                calculate_length_segment(typed.List([nodes[0], nodes[1]])),
                calculate_length_segment(typed.List([nodes[1], nodes[2]])),
                calculate_length_segment(typed.List([nodes[2], nodes[0]])),
            ],
            dtype=np.float64,
        )
    )
    return 2.0 * element_area / max_edge_length


# TODO: review this function, this factors maybe are diffent when used another
# interpolation order for this element
@njit
def calculate_shape_factors_triangle(element_area, nodes):
    """Caclulate shape factors (AKA derivative values) for the triangle"""
    b = np.array(
        [
            nodes[1].position[1] - nodes[2].position[1],
            nodes[2].position[1] - nodes[0].position[1],
            nodes[0].position[1] - nodes[1].position[1],
        ],
        dtype=np.float64,
    )
    c = np.array(
        [
            nodes[2].position[0] - nodes[1].position[0],
            nodes[0].position[0] - nodes[2].position[0],
            nodes[1].position[0] - nodes[0].position[0],
        ],
        dtype=np.float64,
    )
    return b / (2.0 * element_area), c / (2.0 * element_area)


# TODO: implement shape factor calculation functions for other element types here...
