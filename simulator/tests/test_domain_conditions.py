from simulator.domain_conditions import DomainConditions
from pytest_regressions.num_regression import NumericRegressionFixture


def test_domain_conditions(mock_mesh, num_regression, shared_datadir):
    conditions = DomainConditions(
        shared_datadir / "square_cavity_Re_100" / "conditions.toml",
        mock_mesh,
        {"u_1": 0.0, "u_2": 0.0, "p": 0.0001},
    )
    num_regression.check(
        {
            "indices": conditions.initial_conditions[("p", 1)].indices,
            "values": conditions.initial_conditions[("p", 1)].values,
        },
        basename="initial-u_1-condition_type_1",
    )
    num_regression.check(
        {
            "indices": conditions.boundary_conditions[("u_1", 1)].indices,
            "values": conditions.boundary_conditions[("u_1", 1)].values,
        },
        basename="boundary-u_1-condition_type_1",
    )
    num_regression.check(
        {
            "indices": conditions.boundary_conditions[("u_2", 1)].indices,
            "values": conditions.boundary_conditions[("u_2", 1)].values,
        },
        basename="boundary-u_2-condition_type_1",
    )
    num_regression.check(
        {
            "indices": conditions.boundary_conditions[("p", 1)].indices,
            "values": conditions.boundary_conditions[("p", 1)].values,
        },
        basename="boundary-p-condition_type_1",
    )
