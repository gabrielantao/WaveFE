import numpy as np


# TODO: mudar essas funcoes para receber o elemento (obs: dentro do elemento vão os parâmetros necessários e.g. Re)
# TODO: review this assembling if it changes for other elements
# in this case is 2D, so it will change for 1D and 3D, but it could change for different element types
# TODO: revisar a forma que sao passadas as matrizes aqui pq precisa
# inverter a ordem das matrizes de entrada e.g. velocity para o formato C
def assemble_element_rhs_step_1(velocity, b, c, dt, area, Re):
    """Assemble element matrix for step 1"""
    # assemble elemental matrices
    dimension, nodes_per_element = velocity.shape
    rhse = np.zeros((dimension, nodes_per_element))
    u1_sum = np.sum(velocity[0, :])
    u2_sum = np.sum(velocity[1, :])
    u1_mean = u1_sum / nodes_per_element
    v2_mean = u2_sum / nodes_per_element
    Ce = np.zeros((nodes_per_element, nodes_per_element))
    Kme = np.zeros((nodes_per_element, nodes_per_element))
    Kse = np.zeros((nodes_per_element, nodes_per_element))
    # assemble elemental matrices
    for j in range(nodes_per_element):
        for i in range(nodes_per_element):
            # convection term (factor=detJ/24.0=(2*A)/24.0)
            Ce[i, j] = (u1_sum + velocity[0, i]) * b[j]
            Ce[i, j] = Ce[i, j] + (u2_sum + velocity[1, i]) * c[j]
            Ce[i, j] = Ce[i, j] * (2.0 * area) / 24.0
            # difussion term (factor=(2*A)*(1/Re)/2)
            Kme[i, j] = area * (1 / Re) * (b[i] * b[j] + c[i] * c[j])
            # stabilization term (factor=(dt/2)*(2*A)/6)
            Kse[i, j] = u1_mean * (u1_sum * (b[i] * b[j]) + u2_sum * (b[i] * c[j]))
            Kse[i, j] = Kse[i, j] + v2_mean * (
                u1_sum * (b[j] * c[i]) + u2_sum * (c[i] * c[j])
            )
            Kse[i, j] = Kse[i, j] * (dt / 2.0) * (2.0 * area / 6.0)
    # calculate elemental rhs
    rhse[0, :] = np.dot(-(Ce + Kme + Kse), velocity[0, :])
    rhse[1, :] = np.dot(-(Ce + Kme + Kse), velocity[1, :])
    return rhse


def assemble_element_rhs_step_2(velocity, velocity_old, b, c, area):
    """Assemble element matrix for step 2"""
    # NOTE: do not include dt because it was already multiplied in stiffness matrix
    #       see lhs_update subroutine
    # NOTE: add difference term to rhs elemental just like Nithiarasu original code
    velocity_diff = velocity - velocity_old
    # NOTE: we need do add delta_u because => delta_u = u_n - u_{n-1}
    # so we need to use u_n = delta_u + u_{n-1}
    # gradient G1*u1 + G2*u2 (factor=detJ/6.0=2*A/6.0)
    rhse = -(np.dot(b, velocity_old[0, :]) + np.dot(c, velocity_old[1, :])) * (
        area / 3.0
    )
    # add difference term
    rhse = rhse + (
        b * np.sum(velocity_diff[0, :]) + c * np.sum(velocity_diff[1, :])
    ) * (area / 3.0)
    return rhse


def assemble_element_rhs_step_3(velocity_old, pressure, pressure_old, b, c, dt, area):
    """Assemble element matrix for step 3"""
    dimension, nodes_per_element = velocity_old.shape
    grad = np.empty(dimension)
    grad_old = np.empty(dimension)
    u_mean = np.empty(dimension)
    rhse = np.empty(dimension, nodes_per_element)

    # gradient (factor=2*A/6.0)
    grad[0] = np.dot(b, pressure) * (area / 3.0)
    grad[1] = np.dot(c, pressure) * (area / 3.0)
    # gradient old timestep (factor=(2*A)*(dt/4))
    grad_old[0] = np.dot(b, pressure_old) * (dt / 2.0) * area
    grad_old[1] = np.dot(c, pressure_old) * (dt / 2.0) * area
    # stabilization term
    u_mean[0] = np.sum(velocity_old[0, :]) / nodes_per_element
    u_mean[1] = np.sum(velocity_old[1, :]) / nodes_per_element
    # lval = b*umean(1) + c*umean(2)
    rhse[0, :] = -(grad[0] + (b * u_mean[0] + c * u_mean[1]) * grad_old[0])
    rhse[1, :] = -(grad[1] + (b * u_mean[0] + c * u_mean[1]) * grad_old[1])
    return rhse
