import numpy as np
from numba import njit, typed


@njit
def assemble_mass_lumped_lhs(element, nodes, simulation_parameters):
    """Assemble lumped mass matrix M"""
    # TODO: it assembles a first order triangle
    # maybe the type should change depending on interpolation order (e.g. TRIANGLE1, TRIANGLE2, etc.)
    # ref: Nithiarasu eq 7.171 pag 211
    factor = element.area / element.dt / 3.0
    # factor = element.area / 3.0
    return np.array(
        [[factor, 0.0, 0.0], [0.0, factor, 0.0], [0.0, 0.0, factor]], dtype=np.float64
    )


@njit
def assemble_mass_lhs(element, nodes, simulation_parameters):
    """Assemble transient mass matrix M"""
    # TODO: it assembles a first order triangle
    # maybe the type should change depending on interpolation order (e.g. TRIANGLE1, TRIANGLE2, etc.)
    # TODO: check adimensionalization here...
    mass_matrix = np.array(
        [[2.0, 1.0, 1.0], [1.0, 2.0, 1.0], [1.0, 1.0, 2.0]], dtype=np.float64
    )
    return (element.area / 12.0 / element.dt) * mass_matrix


@njit
def assemble_stiffness_lhs(element, nodes, simulation_parameters):
    """
    Calculate stiffness matrix K
    ref: Nithiarasu eq 7.158 pag 209
    """
    stiffness_matrix = np.outer(element.b, element.b) + np.outer(element.c, element.c)
    return element.dt * element.area * stiffness_matrix


@njit
def assemble_element_rhs_step_1(element, nodes, simulation_parameters):
    """Assemble triangle matrix for step 1"""
    rhse_1 = np.zeros(element.nodes_per_element, dtype=np.float64)
    rhse_2 = np.zeros(element.nodes_per_element, dtype=np.float64)
    u_1 = np.array([node.variables["u_1"] for node in nodes])
    u_2 = np.array([node.variables["u_2"] for node in nodes])
    u1_sum = np.sum(u_1)
    u2_sum = np.sum(u_2)
    Re = simulation_parameters["Re"]
    Ce = np.zeros(
        (element.nodes_per_element, element.nodes_per_element), dtype=np.float64
    )
    Kme = np.zeros(
        (element.nodes_per_element, element.nodes_per_element), dtype=np.float64
    )
    Kse = np.zeros(
        (element.nodes_per_element, element.nodes_per_element), dtype=np.float64
    )
    # assemble elemental matrices
    for j in range(element.nodes_per_element):
        for i in range(element.nodes_per_element):
            # convection term (factor=detJ/24.0=(2*A)/24.0)
            Ce[i, j] = (u1_sum + u_1[i]) * element.b[j] + (u2_sum + u_2[i]) * element.c[
                j
            ]
            Ce[i, j] = Ce[i, j] * (2.0 * element.area) / 24.0
            # difussion term (factor=(2*A)*(1/Re)/2)
            Kme[i, j] = (element.area / Re) * (
                element.b[i] * element.b[j] + element.c[i] * element.c[j]
            )
            # stabilization term (factor=(dt/2)*(2*A)/6)
            Kse[i, j] = np.mean(u_1) * (
                u1_sum * (element.b[i] * element.b[j])
                + u2_sum * (element.b[i] * element.c[j])
            )
            Kse[i, j] = Kse[i, j] + np.mean(u_2) * (
                u1_sum * (element.b[j] * element.c[i])
                + u2_sum * (element.c[i] * element.c[j])
            )
            Kse[i, j] = Kse[i, j] * (element.dt / 2.0) * (2.0 * element.area / 6.0)
    # calculate elemental rhs
    rhse_1 = np.dot(-(Ce + Kme + Kse), u_1)
    rhse_2 = np.dot(-(Ce + Kme + Kse), u_2)
    return typed.List([rhse_1, rhse_2])


@njit
def assemble_element_rhs_step_2(element, nodes, simulation_parameters):
    """Assemble triangle matrix for step 2"""
    # NOTE: do not include dt because it was already multiplied in stiffness matrix
    #       see lhs_update subroutine
    # NOTE: add difference term to rhs elemental just like Nithiarasu original code
    u_1 = np.array([node.variables["u_1"] for node in nodes])
    u_2 = np.array([node.variables["u_2"] for node in nodes])
    u_1_old = np.array([node.variables_old["u_1"] for node in nodes])
    u_2_old = np.array([node.variables_old["u_2"] for node in nodes])
    # NOTE: we need do add delta_u because => delta_u = u_n - u_{n-1}
    # so we need to use u_n = delta_u + u_{n-1}
    # gradient G1*u1 + G2*u2 (factor=detJ/6.0=2*A/6.0)
    # add difference term
    rhse = (element.area / 3.0) * (
        element.b * np.sum(u_1 - u_1_old) + element.c * np.sum(u_2 - u_2_old)
    )
    rhse = rhse - (element.area / 3.0) * (
        np.dot(element.b, u_1_old) + np.dot(element.c, u_2_old)
    )
    return typed.List([rhse])


@njit
def assemble_element_rhs_step_3(element, nodes, simulation_parameters):
    """Assemble triangle matrix for step 3"""
    rhse_1 = np.zeros(element.nodes_per_element, dtype=np.float64)
    rhse_2 = np.zeros(element.nodes_per_element, dtype=np.float64)
    pressure = np.array([node.variables["p"] for node in nodes])
    pressure_old = np.array([node.variables_old["p"] for node in nodes])
    u_1_old = np.array([node.variables_old["u_1"] for node in nodes])
    u_2_old = np.array([node.variables_old["u_2"] for node in nodes])
    # gradient (factor=2*A/6.0)
    grad_1 = np.dot(element.b, pressure) * (element.area / 3.0)
    grad_2 = np.dot(element.c, pressure) * (element.area / 3.0)
    # gradient old timestep (factor=(2*A)*(dt/4))
    grad_1_old = np.dot(element.b, pressure_old) * (element.dt / 2.0) * element.area
    grad_2_old = np.dot(element.c, pressure_old) * (element.dt / 2.0) * element.area
    # stabilization term
    u_1_mean = np.mean(u_1_old)
    u_2_mean = np.mean(u_2_old)
    # lval = b*umean(1) + c*umean(2)
    rhse_1 = -(grad_1 + (element.b * u_1_mean + element.c * u_2_mean) * grad_1_old)
    rhse_2 = -(grad_2 + (element.b * u_1_mean + element.c * u_2_mean) * grad_2_old)
    return typed.List([rhse_1, rhse_2])
