"""A generic equation"""
abstract type Equation end

"""A generic single element"""
abstract type ModelParameters end 

"""A generic Wave method (e.g. explicit implicit)"""
abstract type SimulationMethod end

"""A generic Wave model"""
abstract type SimulationModel end


export Equation, ModelParameters, SimulationMethod, SimulationModel
export ConditionType
export SolverType, PreconditionerType
export MatrixType
export InterpolationOrder, Dimension, ElementType


"""
First type condtions specifies the values of variable applied at the boundary (AKA Dirichlet)
Second type condtions specifies the values of the derivative applied at the boundary of the domain. (AKA  Neumann condition)
"""
@enum ConditionType begin
    FIRST = 1
    SECOND = 2
    # TODO [implement other domain conditions]
    ## maybe implement in the future the other conditions (Cauchy and Robin) with combination of these two others
end


"""The type of the solver being used"""
@enum SolverType begin
    CONJUGATE_GRADIENT = 1
end


"""The type of preconditioner used by the solver"""
@enum PreconditionerType begin
    JACOBI = 1 # AKA DiagonalPreconditioner
end


"""The type of matrix assembled"""
@enum MatrixType begin
    DIAGONAL = 1
    SYMMETRIC = 2
    DENSE = 3
end


"""Mesh elements interpolation order"""
@enum InterpolationOrder begin
    ORDER_ONE = 1
    ORDER_TWO = 2
    ORDER_THREE = 3
end


"""Dimension of the mesh"""
@enum Dimension begin
    UNIDIMENSIONAL = 1
    BIDIMENSIONAL = 2
    TRIDIMENSIONAL = 3
end

"""Element type used to import elements from the mesh"""
@enum ElementType begin
    SEGMENT = 1
    TRIANGLE = 2
    QUADRILATERAL = 3
    TETRAHEDRON = 4
    PYRAMID = 5
    PRISM = 6
    HEXAHEDRON = 7
end


"""Auxiliary function to convert a type number of condition into the enum values"""
function get_condition_type(condition_type_number)
    if condition_type_number == 1
        return FIRST::ConditionType
    elseif condition_type_number == 2
        return SECOND::ConditionType
    else
        throw("Not implement group number of type $condition_type_number")
    end
end


"""Get the type of solver selected in the simulation input options"""
function get_solver_type(type)
    if type == "Conjugate Gradient"
        solver_type = CONJUGATE_GRADIENT::SolverType
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for solvers
        throw("Not implemented yet other types of solvers")
    end
    return solver_type
end


"""Get the type of preconditioner selected in the simulation input options"""
function get_solver_preconditioner_type(preconditioner)
    if preconditioner == "Jacobi"
        preconditioner_type = JACOBI::PreconditionerType
    else
        # TODO [add solvers and preconditioner options]
        ## add other options for preconditioners
        throw("Not implemented yet other types of preconditioners")
    end
    return preconditioner_type
end


"""Get the interpolation order for the mesh"""
function get_interpolation_order(interpolation_number)
    if interpolation_number == 1
        interpolation_order = ORDER_ONE::InterpolationOrder
    elseif interpolation_number== 2
        interpolation_order = ORDER_TWO::InterpolationOrder
    elseif interpolation_number == 3
        interpolation_order = ORDER_THREE::InterpolationOrder
    else
        throw("Not implemented interpolation order $interpolation_number")
    end
    return interpolation_order
end


"""Get the mesh dimension"""
function get_dimension_number(dimension_number)
    if dimension_number == 1
        dimension = UNIDIMENSIONAL::Dimension
    elseif dimension_number== 2
        dimension = BIDIMENSIONAL::Dimension
    elseif dimension_number == 3
        dimension = TRIDIMENSIONAL::Dimension
    else
        throw("Invalid dimension $dimension_number it should be 1, 2 or 3")
    end
    return dimension
end


"""Get the type of the element from the mesh"""
function get_element_type(name::String)
    type_map = Dict{String, ElementType}(
        "Segment" => SEGMENT::ElementType,
        "Triangle" => TRIANGLE::ElementType,
        "Quadrangle" => QUADRILATERAL::ElementType,
        "Tetrahedron" => TETRAHEDRON::ElementType,
        "Hexahedron" => HEXAHEDRON::ElementType,
        "Pyramid" => PYRAMID::ElementType,
        "Prism" => PRISM::ElementType
    )
    return type_map[split(name)[1]]
end