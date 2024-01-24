import pytest
import numpy as np

from simulator.element import NodesHandler
from simulator.assembler import Assembler, EquationSide
from simulator.cbs_models.models.semi_implicit.elements_assembling import (
    assemble_mass_lumped_lhs,
    assemble_mass_lhs,
    assemble_stiffness_lhs,
    assemble_element_rhs_step_1,
    assemble_element_rhs_step_2,
    assemble_element_rhs_step_3,
)
from simulator.element import ElementType, NodesHandler, ElementsContainer
from simulator.mesh import Mesh


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
    connectivity = np.loadtxt(
        shared_datadir / "connectivity.csv",
        delimiter=",",
        dtype=np.int32,
    )
    # these values are in csv shifted a unit so it should be sfited back
    return connectivity - 1


@pytest.fixture
def coordinate_matrix(shared_datadir):
    """coordinate matrix"""
    return np.loadtxt(
        shared_datadir / "coordinates.csv",
        delimiter=",",
        dtype=np.float64,
    )


@pytest.fixture
def boundary_matrix(shared_datadir):
    """side matrix"""
    sides = np.loadtxt(
        shared_datadir / "boundaries.csv",
        delimiter=",",
        dtype=np.int32,
    )
    # these values are in csv shifted a unit so it should be shifted back
    return sides - 1


@pytest.fixture
def nodes_handler(coordinate_matrix):
    nodes_handler = NodesHandler(2, coordinate_matrix)
    nodes_handler.update_variable_values("u_1", np.zeros(2601))
    nodes_handler.update_variable_values("u_2", np.zeros(2601))
    nodes_handler.update_variable_values("p", np.zeros(2601))
    nodes_handler.update_variable_old_values("u_1", np.zeros(2601))
    nodes_handler.update_variable_old_values("u_2", np.zeros(2601))
    nodes_handler.update_variable_old_values("p", np.zeros(2601))
    return nodes_handler


@pytest.fixture
def basic_matrix_vum(shared_datadir):
    # remember that sizes are optional here
    dNkdx = np.loadtxt(
        shared_datadir / "dNkdx.csv",
        delimiter=",",
        dtype=np.float64,
    )

    # the double of the element area
    detJ = np.loadtxt(
        shared_datadir / "detJ.csv",
        delimiter=",",
        dtype=np.float64,
    )

    elcoe_e = np.loadtxt(
        shared_datadir / "elcoe_e.csv",
        delimiter=",",
        dtype=np.float64,
    )

    face_norm = np.loadtxt(
        shared_datadir / "face_norm.csv",
        delimiter=",",
        dtype=np.float64,
    )

    # element specific size
    alen_e = np.loadtxt(
        shared_datadir / "alen_e.csv",
        delimiter=",",
        dtype=np.float64,
    )

    # only for conjugate gradient
    pdiagE = np.loadtxt(
        shared_datadir / "pdiagE.csv",
        delimiter=",",
        dtype=np.float64,
    )

    gstifE = np.loadtxt(
        shared_datadir / "gstifE.csv",
        delimiter=",",
        dtype=np.float64,
    )

    return {
        "dNkdx": dNkdx,
        "detJ": detJ,
        "elcoe_e": elcoe_e,
        "face_norm": face_norm,
        "alen_e": alen_e,
        "pdiagE": pdiagE,
        "gstifE": gstifE,
    }


@pytest.fixture
def modified_basic_matrix_set2(basic_matrix_vum, basic_initial_variables):
    """Modify original matrices to obtain separeted terms b,c, and areas"""
    b = [
        basic_matrix_vum["dNkdx"][i : i + 3]
        for i in range(0, len(basic_matrix_vum["dNkdx"]), 6)
    ]
    c = [
        basic_matrix_vum["dNkdx"][i : i + 3]
        for i in range(3, len(basic_matrix_vum["dNkdx"]), 6)
    ]
    return {
        "b": np.array(b).reshape(
            (basic_initial_variables["nelem"], basic_initial_variables["nep"])
        ),
        "c": np.array(c).reshape(
            (basic_initial_variables["nelem"], basic_initial_variables["nep"])
        ),
        "areas": basic_matrix_vum["detJ"] / 2.0,
    }


@pytest.fixture
def element_triangles(connectivity_matrix):
    return ElementsContainer(
        ElementType.TRIANGLE.value,
        connectivity_matrix.astype(np.int32),
    )


# TODO: colocar a fixture com condição de contorno aqui para o caso da caixa quadrada


@pytest.fixture
def assembler():
    assembler = Assembler()
    # register functions for left-hand side of solved equations
    assembler.register_function(
        "step 1 mass_lumped",
        EquationSide.LHS,
        ElementType.TRIANGLE,
        assemble_mass_lumped_lhs,
    )
    assembler.register_function(
        "step 1 mass_transient",
        EquationSide.LHS,
        ElementType.TRIANGLE,
        assemble_mass_lhs,
    )
    assembler.register_function(
        "step 2 stiffness",
        EquationSide.LHS,
        ElementType.TRIANGLE,
        assemble_stiffness_lhs,
    )
    assembler.register_function(
        "step 3 mass_lumped",
        EquationSide.LHS,
        ElementType.TRIANGLE,
        assemble_mass_lumped_lhs,
    )
    assembler.register_function(
        "step 3 mass_transient",
        EquationSide.LHS,
        ElementType.TRIANGLE,
        assemble_mass_lhs,
    )
    # register functions to be used to assemble the elements
    # for right-side of each equation solved by the model
    assembler.register_function(
        "step 1",
        EquationSide.RHS,
        ElementType.TRIANGLE,
        assemble_element_rhs_step_1,
    )
    assembler.register_function(
        "step 2",
        EquationSide.RHS,
        ElementType.TRIANGLE,
        assemble_element_rhs_step_2,
    )
    assembler.register_function(
        "step 3",
        EquationSide.RHS,
        ElementType.TRIANGLE,
        assemble_element_rhs_step_3,
    )
    # register how many variables is solved by each equation
    assembler.register_total_variables_assembled("step 1", 2)
    assembler.register_total_variables_assembled("step 2", 1)
    assembler.register_total_variables_assembled("step 3", 2)
    return assembler


@pytest.fixture
def mock_mesh(
    nodes_handler, element_triangles, modified_basic_matrix_set2, shared_datadir
):
    # TODO: remember to load rigth values for b and c calculated for this mesh
    mesh = Mesh(shared_datadir / "mesh.msh")
    mesh.nodes_handler = nodes_handler
    mesh.element_containers = {ElementType.TRIANGLE.value: element_triangles}
    for element_id in range(
        mesh.element_containers[ElementType.TRIANGLE.value].total_elements
    ):
        mesh.element_containers[ElementType.TRIANGLE.value].elements[
            element_id
        ].b = modified_basic_matrix_set2["b"][element_id, :]
        mesh.element_containers[ElementType.TRIANGLE.value].elements[
            element_id
        ].c = modified_basic_matrix_set2["c"][element_id, :]
        mesh.element_containers[ElementType.TRIANGLE.value].elements[
            element_id
        ].area = modified_basic_matrix_set2["areas"][element_id]
    return mesh
