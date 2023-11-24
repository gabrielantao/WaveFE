# modulo com codigo modificado fortran
import numpy as np
from numba import typed, types
import pytest
from simulator.element import ElementType, NodesHandler
from simulator.mesh import Mesh

# TODO: depois de acertar esses testes, fazer tudo via regression quando já tiver os valores corretos
# lembrar de apagar essa chamada pro simulator compilado fortran e as fixtures correspondnetes como estão
# para tal, recriar as fixtures da forma correta usanod já a forma que estão implementadas aqui
from simulator.cbs import cbs_simulator


@pytest.fixture
def mock_mesh(
    nodes_handler, element_triangles, modified_basic_matrix_set2, shared_datadir
):
    # TODO: change this to use real instance of Mesh
    # from collections import namedtuple
    # Mesh = namedtuple("Mesh", ["nodes", "element_containers", "total_nodes"])
    # TODO: remember to load real mesh here, now it's just a dumy mesh only to instantiate the mesh
    mesh = Mesh(shared_datadir / "mesh.msh")
    mesh.nodes = nodes_handler
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


def test_calculate_step1(
    mock_mesh,
    assembler,
    square_case_configs,
    basic_initial_variables,
    connectivity_matrix,
    basic_matrix_vum,
    shared_datadir,
):
    # doing it for step 2 than velocity is efective of step 1
    vel = np.loadtxt(
        shared_datadir / "old_results" / "v_real_clean" / "vefe_00001.csv",
        delimiter=",",
    )
    timestep = np.loadtxt(
        shared_datadir / "old_results" / "dt_clean" / "dt_00002.csv",
        delimiter=",",
    )
    temperature = np.zeros(basic_initial_variables["npoin"])

    mock_mesh.nodes.update_variables("u_1", vel[:, 0])
    mock_mesh.nodes.update_variables("u_2", vel[:, 1])
    # mock_mesh.nodes.update_variables("t", temperature)  # not used here
    # update element local timesteps
    for element_id in range(
        mock_mesh.element_containers[ElementType.TRIANGLE.value].total_elements
    ):
        mock_mesh.element_containers[ElementType.TRIANGLE.value].elements[
            element_id
        ].dt = timestep[element_id]
    simulation_parameters = typed.Dict.empty(types.unicode_type, types.float64)
    simulation_parameters["Re"] = square_case_configs["Re"]
    new_fortran_rhs = assembler.assemble_rhs("step 1", mock_mesh, simulation_parameters)

    # TODO: remove this call here after include a regression
    fortran_rhs = cbs_simulator.step1(
        basic_initial_variables["convection_type"],
        connectivity_matrix.transpose() + 1,
        basic_initial_variables["ani"],
        square_case_configs["ra"],
        square_case_configs["ri"],
        square_case_configs["pr"],
        timestep,
        vel.transpose(),
        temperature,
        basic_matrix_vum["dNkdx"],
        basic_matrix_vum["detJ"],
    )
    # TODO: use a regression here
    assert np.allclose(new_fortran_rhs, fortran_rhs.transpose())


def test_calculate_step2(
    mock_mesh,
    assembler,
    square_case_configs,
    connectivity_matrix,
    basic_matrix_vum,
    shared_datadir,
):
    # doing it for step 2 than old velocity is efective of step 1
    vel_old = np.loadtxt(
        shared_datadir / "old_results" / "v_real_clean" / "vefe_00001.csv",
        delimiter=",",
    )
    vel_intermediate = np.loadtxt(
        shared_datadir / "old_results" / "vint_clean" / "vint_00002.csv",
        delimiter=",",
    )
    mock_mesh.nodes.update_variables_old("u_1", vel_old[:, 0])
    mock_mesh.nodes.update_variables_old("u_2", vel_old[:, 1])
    mock_mesh.nodes.update_variables("u_1", vel_intermediate[:, 0])
    mock_mesh.nodes.update_variables("u_2", vel_intermediate[:, 1])
    new_fortran_rhs = assembler.assemble_rhs("step 2", mock_mesh)

    # TODO: remove this call here after include a regression
    fortran_rhs = cbs_simulator.step2(
        connectivity_matrix.transpose() + 1,
        vel_intermediate.transpose(),
        vel_old.transpose(),
        basic_matrix_vum["dNkdx"],
        basic_matrix_vum["detJ"],
        square_case_configs["theta"],
    )
    # TODO: this should be a regression
    assert np.allclose(new_fortran_rhs, fortran_rhs.reshape((2601, 1)))


def test_calculate_step3(
    mock_mesh,
    assembler,
    connectivity_matrix,
    basic_matrix_vum,
    shared_datadir,
):
    vel_old = np.loadtxt(
        shared_datadir / "old_results" / "v_real_clean" / "vefe_00001.csv",
        delimiter=",",
    )
    pressure_old = np.loadtxt(
        shared_datadir / "old_results" / "pressure_clean" / "pres2_00001.csv",
        delimiter=",",
    )
    pressure = np.loadtxt(
        shared_datadir / "old_results" / "pressure_clean" / "pres2_00002.csv",
        delimiter=",",
    )
    timestep = np.loadtxt(
        shared_datadir / "old_results" / "dt_clean" / "dt_00002.csv",
        delimiter=",",
    )
    mock_mesh.nodes.update_variables_old("u_1", vel_old[:, 0])
    mock_mesh.nodes.update_variables_old("u_2", vel_old[:, 1])
    mock_mesh.nodes.update_variables_old("p", pressure_old)
    mock_mesh.nodes.update_variables("p", pressure)
    # update element local timesteps
    for element_id in range(
        mock_mesh.element_containers[ElementType.TRIANGLE.value].total_elements
    ):
        mock_mesh.element_containers[ElementType.TRIANGLE.value].elements[
            element_id
        ].dt = timestep[element_id]

    new_fortran_rhs = assembler.assemble_rhs("step 3", mock_mesh)

    # TODO: remove this call here after include a regression
    fortran_rhs = cbs_simulator.step3(
        connectivity_matrix.transpose() + 1,
        vel_old.transpose(),
        pressure,
        pressure_old,
        basic_matrix_vum["dNkdx"],
        basic_matrix_vum["detJ"],
        timestep,
    )
    # TODO: should be regression
    assert np.allclose(new_fortran_rhs, fortran_rhs.transpose())
