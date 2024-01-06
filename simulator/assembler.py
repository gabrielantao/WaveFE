from enum import Enum
import numpy as np
import scipy as sp
from numba import njit, typed
from numba.core import types


# TODO: check if this should be moved to another module
class EquationSide(Enum):
    """This enum just creates labels to identify the side of the equation"""

    RHS = 1  # right-hand side
    LHS = 2  # left-hand side


class Assembler:
    """This class register and call assembling functions given a equation name and a element list to be assembled"""

    def __init__(self):
        self.assembling_functions_register = {}
        # it holds for each equation how much variables are solved
        # it indicates the size of global vector assembled which must have dimension (total_variables, total_assemble_variables)
        self.lhs_total_variables_assembled = {}

    def get_assembling_function_name(self, equation_name, equation_side, element_type):
        """
        Get the registered equation by concatenating as 'equation_name/equation_side/element_type' being:
        - equation_name a string to identify the equation or the matrix,
        - equation_side a number to identify equation side RHS=1 and LHS=2 (see EquationSide enum)
        - element_type a number to identify the element type (see ElementType enum)
        """
        return f"{equation_name}/{equation_side}/{element_type}"

    def register_function(
        self, equation_name, equation_side, element_type, assembling_function
    ):
        """
        Register a function to be used to assembling elements of type element_type for the equation named equation_name
        See get_assembling_function_name to know how the functions are named.
        """
        self.assembling_functions_register[
            self.get_assembling_function_name(
                equation_name, equation_side, element_type
            )
        ] = assembling_function

    def get_registered_function(self, equation_name, equation_side, element_type):
        """This function try to retrive the assembling function for a equation and element type passed as argument"""
        assembling_function_name = self.get_assembling_function_name(
            equation_name, equation_side, element_type
        )
        if assembling_function_name in self.assembling_functions_register:
            return self.assembling_functions_register[assembling_function_name]
        error_message = f"assemble equation: {equation_name}\nside of the equation: {equation_side}\nelement of type: {element_type}\n"
        raise NotImplementedError(
            "There is no assembling function registered for:\n" + error_message
        )

    def register_total_variables_assembled(
        self, equation_name, total_variables_assembled
    ):
        """
        Register the amount of variables assembled in LHS assembling for a given equation.
        This amount represents how many variables must be solved in this equation.
        e.g. for step 1 in CBS it can be the velocities in two dimensions u_1 and u_2.
        """
        self.lhs_total_variables_assembled[equation_name] = total_variables_assembled

    def get_total_variables_assembled(self, equation_name):
        """
        Get the of variables assembled in LHS assembling for a given equation.
        """
        if equation_name in self.lhs_total_variables_assembled:
            return self.lhs_total_variables_assembled[equation_name]
        raise NotImplementedError(
            f"There is no registered value for total variables assembled in LHS for the equation {equation_name}"
        )

    def assemble_lhs(
        self,
        equation_name,
        mesh,
        simulation_parameters=typed.Dict.empty(types.unicode_type, types.float64),
    ):
        """Do the LHS assembling process for a equation named equation_name all elements in the element_containers from the mesh"""
        # dictionary to be used to hold data for indices and values of dictionary
        global_matrix_values = typed.Dict.empty(
            types.UniTuple(types.int64, 2), types.float64
        )
        # assemble each container depending on the registered element type
        for element_container in mesh.get_element_containers():
            assembling_function = self.get_registered_function(
                equation_name, EquationSide.LHS.value, element_container.element_type
            )
            _assemble_element_container_lhs(
                assembling_function,
                mesh.nodes_handler,
                element_container.elements,
                simulation_parameters,
                global_matrix_values,
            )
        # convert the assembled data of the matrix to the array of indices and values
        # in order to get build the sparse matrix for RHS of this equation
        indices_row, indices_column, values = _get_indices_values_sparse_matrix(
            global_matrix_values
        )
        return sp.sparse.csr_array(
            (values, (indices_row, indices_column)),
            shape=(mesh.nodes_handler.total_nodes, mesh.nodes_handler.total_nodes),
        )

    def assemble_rhs(
        self,
        equation_name,
        mesh,
        simulation_parameters=typed.Dict.empty(types.unicode_type, types.float64),
    ):
        """
        Do the RHS assembling process for a equation named equation_name all elements in the element_containers from the mesh
        This function returns a dictionary with values for each assembled variable of the equation LHS.
        This is done like this because some steps of the model can assemble multiple variables together
        e.g. step 1 and step 3 can assemble all velocity directions
        """
        # dictionary to be used to hold data for variable name and array with values for LHS
        total_variables = self.get_total_variables_assembled(equation_name)
        global_array_values = np.zeros(
            (mesh.nodes_handler.total_nodes, total_variables), dtype=np.float64
        )
        # assemble each container depending on the registered element type
        for element_container in mesh.get_element_containers():
            assembling_function = self.get_registered_function(
                equation_name, EquationSide.RHS.value, element_container.element_type
            )
            _assembling_element_container_rhs(
                assembling_function,
                mesh.nodes_handler,
                element_container.elements,
                simulation_parameters,
                global_array_values,
            )
        return global_array_values


@njit
def _assemble_element_container_lhs(
    assembling_elemental_function,
    nodes,
    elements,
    simulation_parameters,
    global_matrix_values,
):
    """
    This assembles all elements in a global matrix (vector) RHS
    assembling_elemental_function: the function used to assemble elements
    elements: are the elements to be assembled
    simulation_parameters: are values that can be passed to the assembled elements
    global_matrix_values: is a dictionary that holds indices and values of assembled matrix
    """
    for element in elements:
        # the assembled_elemental comes as a numpy two dimension array
        assembled_elemental = assembling_elemental_function(
            element,
            element.get_nodes(nodes),
            simulation_parameters,
        )
        # assemble elemental matrix to the global matrix dict
        # TODO: could be optimized to not assemble off-diag values for mass lumped matrix
        # (nor the off-diag values for lower values for symmetric matrices, but
        # I'm not sure if this case worth the effort)
        for column in range(element.nodes_per_element):
            for row in range(element.nodes_per_element):
                row_global = element.node_ids[row]
                column_global = element.node_ids[column]
                # if is a diagonal position or if it already exist in dict
                # then just sum the value, otherwise just insert new value to the dict
                if (row_global, column_global) in global_matrix_values:
                    global_matrix_values[
                        (row_global, column_global)
                    ] += assembled_elemental[row, column]
                else:
                    global_matrix_values[
                        (row_global, column_global)
                    ] = assembled_elemental[row, column]


# TODO: maybe this could be parallelized
@njit
def _get_indices_values_sparse_matrix(global_matrix_values):
    """This converts the dict data of the sparse matrix into the arrays of indices and values"""
    total_values = len(global_matrix_values)
    indices_row = np.empty(total_values, dtype=np.int32)
    indices_column = np.empty(total_values, dtype=np.int32)
    values = np.empty(total_values, dtype=np.float64)
    i = 0
    for index, value in global_matrix_values.items():
        indices_row[i], indices_column[i] = index
        values[i] = value
        i += 1
    return indices_row, indices_column, values


@njit
def _assembling_element_container_rhs(
    assembling_elemental_function,
    nodes,
    elements,
    simulation_parameters,
    global_matrix_values,
):
    """
    This assembles all elements in a global matrix (vector) LHS.
    elements: are the elements to be assembled
    simulation_parameters: are values that can be passed to the assembled elements
    global_matrix_values: is a array that holds indices and values of assembled matrix
    """
    for element in elements:
        # this assembled_elemental comes as dict[str, np.ndarray] for each variable assembled in LHS
        # for the current equation
        element_nodes = element.get_nodes(nodes)
        assembled_elemental = assembling_elemental_function(
            element, element_nodes, simulation_parameters
        )
        total_assembled_variables = len(assembled_elemental)
        # assemble elemental matrix to the global arrays dict
        for assembled_variable_index in range(total_assembled_variables):
            total_element_rows = assembled_elemental[assembled_variable_index].shape[0]
            for row in range(total_element_rows):
                global_row = element.node_ids[row]
                global_matrix_values[global_row][
                    assembled_variable_index
                ] += assembled_elemental[assembled_variable_index][row]
