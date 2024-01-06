import numpy as np
import pytest


# TODO: testar somente um elemento isolado aqui ...
# def test_geometry(mock_mesh, nodes_handler, num_regression, shared_datadir):
#     for element_container in mock_mesh.get_element_containers():
#         calculator = GeometryCalculator(element_container.element_type)
#         calculate_shape_factor = calculator.get_shape_factors_function()
#         for element in element_container.elements:
#             element_nodes = element.get_nodes(nodes_handler)
#             b, c = calculate_shape_factor(
#                 element.area, element_nodes
#             )
