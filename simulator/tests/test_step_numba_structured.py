# modulo com codigo modificado fortran
import numpy as np
import pytest

from simulator.cbs import cbs_simulator


# TODO: depois de acertar esses testes, fazer tudo via regression quando já tiver os valores corretos
# TODO: depois disso, fazer o refactor para organizar as funções de assembling elementar


# TODO: alterar todos aqui para fazerem regression das funções vindas do fortran
@pytest.fixture
def basic_matrix_set(
    basic_initial_variables, connectivity_matrix, coordinate_matrix, boundary_matrix
):
    # remeber that sizes are optional here
    dNkdx, detJ = cbs_simulator.shape_function_derivatives(
        connectivity_matrix.transpose(),
        coordinate_matrix.transpose(),
        basic_initial_variables["nelem"],
        basic_initial_variables["npoin"],
        basic_initial_variables["nep"],
    )
    elcoe_e = cbs_simulator.mass_matrix(basic_initial_variables["nep"], detJ)
    face_norm = cbs_simulator.get_normals(
        basic_initial_variables["bsid"],
        boundary_matrix.transpose(),
        coordinate_matrix.transpose(),
    )
    alen_e = cbs_simulator.element_size(
        basic_initial_variables["ippn1"],
        connectivity_matrix.transpose(),
        detJ,
        coordinate_matrix.transpose(),
    )
    # only for conjugate gradient
    pdiagE, gstifE = cbs_simulator.pstiff(
        basic_initial_variables["nelem"],
        basic_initial_variables["nep"],
        basic_initial_variables["elemConSize"],
        basic_initial_variables["GiD"],
        dNkdx,
        detJ,
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
def modified_basic_matrix_set(basic_matrix_set):
    """Modify original matrices to obtain separeted terms b,c, and areas"""
    b = [
        basic_matrix_set["dNkdx"][i : i + 3]
        for i in range(0, len(basic_matrix_set["dNkdx"]), 6)
    ]
    c = [
        basic_matrix_set["dNkdx"][i : i + 3]
        for i in range(3, len(basic_matrix_set["dNkdx"]), 6)
    ]
    return {
        "b": np.array(b, order="F").transpose(),
        "c": np.array(c, order="F").transpose(),
        "areas": basic_matrix_set["detJ"] / 2.0,
    }


# # TODO: ajeitar o teste, provavelmente tem problema nos indices
# def test_calculate_step1(
#     square_case_configs,
#     basic_initial_variables,
#     connectivity_matrix,
#     basic_matrix_set,
#     modified_basic_matrix_set,
#     shared_datadir,
# ):
#     timestep = np.loadtxt(
#         shared_datadir / "old_results" / "dt_clean" / "dt_00001.csv",
#         delimiter=",",
#     )
#     vel = np.loadtxt(
#         shared_datadir / "old_results" / "v_real_clean" / "vefe_00001.csv",
#         delimiter=",",
#     ).transpose()
#     temperature = np.zeros(basic_initial_variables["npoin"])

#     new_numba_rhs = assemble_rhs_step_1(
#         vel,
#         connectivity_matrix,
#         modified_basic_matrix_set["b"],
#         modified_basic_matrix_set["c"],
#         timestep,
#         modified_basic_matrix_set["areas"],
#         square_case_configs["Re"],
#     )
#     fortran_rhs = cbs_simulator.step1(
#         basic_initial_variables["convection_type"],
#         connectivity_matrix,
#         basic_initial_variables["ani"],
#         square_case_configs["ra"],
#         square_case_configs["ri"],
#         square_case_configs["pr"],
#         timestep,
#         vel,
#         temperature,
#         basic_matrix_set["dNkdx"],
#         basic_matrix_set["detJ"],
#     )
#     assert np.all(np.isclose(new_numba_rhs, fortran_rhs))


def test_calculate_step2(
    assembler,
    square_case_configs,
    basic_initial_variables,
    connectivity_matrix,
    basic_matrix_set,
    modified_basic_matrix_set,
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
    # TODO: preencher as variaveis com essas velocidades
    # TODO: criar fixtures com elementos
    new_fortran_rhs = assembler()

    fortran_rhs = cbs_simulator.step2(
        connectivity_matrix,
        vel_intermediate.transpose(),
        vel_old.transpose(),
        basic_matrix_set["dNkdx"],
        basic_matrix_set["detJ"],
        square_case_configs["theta"],
    )
    assert np.all(np.isclose(new_fortran_rhs, fortran_rhs))


# def test_calculate_step3(
#     basic_initial_variables,
#     connectivity_matrix,
#     basic_matrix_set,
#     modified_basic_matrix_set,
#     shared_datadir,
# ):
#     vel_old = np.loadtxt(
#         shared_datadir / "old_results" / "v_real_clean" / "vefe_00001.csv",
#         delimiter=",",
#     ).transpose()
#     pressure_old = np.loadtxt(
#         shared_datadir / "old_results" / "pressure_clean" / "pres2_00001.csv",
#         delimiter=",",
#     ).transpose()
#     pressure = np.loadtxt(
#         shared_datadir / "old_results" / "pressure_clean" / "pres2_00002.csv",
#         delimiter=",",
#     ).transpose()
#     timestep = np.loadtxt(
#         shared_datadir / "old_results" / "dt_clean" / "dt_00002.csv",
#         delimiter=",",
#     )
#     new_fortran_rhs = assembling_global.assemble_rhs_step_3(
#         vel_old,
#         pressure,
#         pressure_old,
#         connectivity_matrix,
#         modified_basic_matrix_set["b"],
#         modified_basic_matrix_set["c"],
#         timestep,
#         modified_basic_matrix_set["areas"],
#     )
#     fortran_rhs = cbs_simulator.step3(
#         connectivity_matrix,
#         vel_old,
#         pressure,
#         pressure_old,
#         basic_matrix_set["dNkdx"],
#         basic_matrix_set["detJ"],
#         timestep,
#     )
#     assert np.all(np.isclose(new_fortran_rhs, fortran_rhs))
