import pytest
import numpy as np
from numba import typed

from simulator.element import NodesHandler
from simulator.assembler import Assembler, EquationSide
from simulator.semi_implicit.assembing_elements import (
    assemble_element_rhs_step_1,
    assemble_element_rhs_step_2,
    assemble_element_rhs_step_3,
)
from simulator.element import ElementType


@pytest.fixture
def square_case_configs():
    """Configs for square case with Re=100"""
    return {
        # input from file
        "Re": 100.0,
        "ra": 1000.0,
        "ri": 0.0,
        "pr": 0.71,
        # solver_opt = 1 (Conjugate Gradient) = 2 (Gaussian Elimination)
        "solver_opt": 1,
        "dtfixed": 0,
        "transient_on": 0,
        "dtfix": 1.0e-5,
        "csafm": 0.7,
        "theta": np.array([1.0, 1.0]),
        "reltoler": 0.1,
        "abstoler": 1.0e-18,
    }


@pytest.fixture
def basic_initial_variables(square_case_configs):
    data = {}
    # number of elements
    data["nelem"] = 5000
    # number of nodes
    data["npoin"] = 2601
    # Number of Nodes in Element
    data["nep"] = 3
    # Number of Element Sides
    data["nsid"] = 3
    # Number of Points per Side
    data["nsidp"] = 2
    # Size of Boundary Information Array
    data["bsid"] = data["nsidp"] + 2
    # number of boundaries
    data["nboun"] = 200
    # Number of off-diagonal components in local element array (halved due to symmetry)
    data["gsdim"] = 3

    data["elemConSize"] = data["nep"] * data["nelem"]

    # Define which (local) element nodes make up each element side
    ippn1 = np.empty((data["nsidp"], data["nsid"]), dtype=int)
    ippn1[0][0] = 2  # side 1
    ippn1[0][1] = 3  # side 2
    ippn1[0][2] = 1  # side 3
    ippn1[1][0] = 3  # side 1
    ippn1[1][1] = 1  # side 2
    ippn1[1][2] = 2  # side 3
    data["ippn1"] = ippn1

    # Off-diagonal Components
    GiD = np.empty((2, data["gsdim"]), order="F", dtype=int)
    # Component a12 of A matrix (3x3)
    GiD[0][0] = 1
    GiD[1][0] = 2
    # Component a13 of A matrix (3x3)
    GiD[0][1] = 1
    GiD[1][1] = 3
    # Component a23 of A matrix (3x3)
    GiD[0][2] = 2
    GiD[1][2] = 3
    data["GiD"] = GiD

    # TODO: criar aqui a variavel
    # unkno(2, npoin)

    # calculate ani (reynolds inverse) here
    # NOTE: only for forced and mixed convection problems
    data["ani"] = 1.0 / square_case_configs["Re"]

    data["nodes_per_element"] = 3
    data["total_elements"] = 5000
    data["total_nodes"] = 2601
    # free stream values vel_x, vel_y, pressure, temperature
    data["cinf"] = [0.0, 0.0, 0.0001, 0.0]
    # (1 - Natural, 0 - Mixed/Forced)
    data["convection_type"] = 0
    return data


@pytest.fixture
def connectivity_matrix(shared_datadir):
    """connectivity matrix for square case"""
    return np.loadtxt(
        shared_datadir / "connectivity.csv",
        delimiter=",",
        dtype=np.int32,
    )


@pytest.fixture
def coordinate_matrix(shared_datadir):
    # coordinate matrix
    return np.loadtxt(
        shared_datadir / "coordinates.csv",
        delimiter=",",
        dtype=np.float64,
    )


@pytest.fixture
def boundary_matrix(shared_datadir):
    # side matrix
    return np.asfortranarray(
        np.loadtxt(
            shared_datadir / "boundaries.csv",
            delimiter=",",
            dtype=np.int32,
        )
    )


@pytest.fixture
def nodes_handler(coordinate_matrix):
    nodes_handler = NodesHandler(2, coordinate_matrix)
    nodes_handler.update_variables("u_1", np.zeros(2601))
    nodes_handler.update_variables("u_2", np.zeros(2601))
    nodes_handler.update_variables("p", np.zeros(2601))
    nodes_handler.update_variables_old("u_1", np.zeros(2601))
    nodes_handler.update_variables_old("u_2", np.zeros(2601))
    nodes_handler.update_variables_old("p", np.zeros(2601))
    return nodes_handler


# TODO: colocar a fixture com condição de contorno aqui para o caso da caixa quadrada
@pytest.fixture
def assembler():
    assembler = Assembler()
    # TODO: register functions for LHS
    # register functions to be used to assemble the elements
    # for right-side of each equation solved by the model
    assembler.register_function(
        "step 1",
        EquationSide.RHS.value,
        ElementType.TRIANGLE.value,
        assemble_element_rhs_step_1,
    )
    assembler.register_function(
        "step 2",
        EquationSide.RHS.value,
        ElementType.TRIANGLE.value,
        assemble_element_rhs_step_2,
    )
    assembler.register_function(
        "step 3",
        EquationSide.RHS.value,
        ElementType.TRIANGLE.value,
        assemble_element_rhs_step_3,
    )
    return assembler
