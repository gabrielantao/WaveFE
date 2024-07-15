"""
references:

Fundamentals of Finite Element Analysis - Hutton (2004) cap 6
The Finite Element Method - Its basis and fundamentals - Zienkiewicz et al. (7nd ed) cap 6
Fundamentals of the Finite Element Method for Head and Mass Transfer - Nithiarasu & Lewis, Seetharamu (2nd ed) cap 7
"""

using Symbolics

# TODO [review shape functions]
# - add other options of interpolation (see Pascal triangle polinomials) to be used
#   as basis for the deduction of other shape functions with another number of points
#   e.g. "mini" triangle element

struct QuadratureParameters
    positions::Vector{Float64}
    weights::Vector{Float64}
end


# variables for square element
# TODO: think if it should use r, s, t or ξ, η, ζ as notation for these functions
@variables r, s, t
# length, area, volume
@variables L, A, V

∂_∂s = Differential(s)
∂_∂r = Differential(r)
∂_∂t = Differential(t)

# TODO: REMOVE THIS only debug
"""Mesh elements interpolation order"""
@enum InterpolationOrder begin
    ORDER_ONE = 1
    ORDER_TWO = 2
    ORDER_THREE = 3
end
using LinearAlgebra
#####


"""
Get the triangle shape function based on interpolation order.

Here the parameters r, s, t correspond to the area coordinates of triangle
r => L_1
s => L_2
t => L_3
"""
function get_triangle_shape_functions(interpolation_order::InterpolationOrder)
    # equation 6.41 cap 6 Hutton
    if interpolation_order == ORDER_ONE::InterpolationOrder
        N_1 = 1.0 - r - s
        N_2 = r
        N_3 = s
        return [N_1 N_2 N_3]
    # equation 6.46 cap 6 Hutton
    elseif interpolation_order == ORDER_TWO::InterpolationOrder
        N_1 = r * (2.0 * r - 1.0)
        N_2 = s * (2.0 * s - 1.0)
        N_3 = t * (2.0 * t - 1.0)
        N_4 = 4.0 * r * s
        N_5 = 4.0 * s * t
        N_6 = 4.0 * r * t
        return [N_1 N_2 N_3 N_4 N_5 N_6]
    elseif interpolation_order == ORDER_THREE::InterpolationOrder
        # TODO [implement higher order bidimensional elements]
        # implement this interpolation order shape functions
        # can be found in section 6.2.1.4 pag 144 of Zienkiewicz et al.
        throw("Tridimensional shape functions not implement.")
    end
end


"""Get the quadrilateral shape function based on interpolation order."""
function get_quadrilateral_shape_functions(interpolation_order::InterpolationOrder)
    # eq 6.56 cap 6 pag 186 Hutton
    if interpolation_order == ORDER_ONE::InterpolationOrder
        N_1 = (1.0 / 4.0) * (1.0 - r) * (1.0 - s)
        N_2 = (1.0 / 4.0) * (1.0 + r) * (1.0 - s)
        N_3 = (1.0 / 4.0) * (1.0 + r) * (1.0 + s)
        N_4 = (1.0 / 4.0) * (1.0 - r) * (1.0 + s)
        return [N_1 N_2 N_3 N_4]
    # this is the eight node version 
    # eq 6.59 cap 6 pag 186 Hutton
    elseif interpolation_order == ORDER_TWO::InterpolationOrder
        N_1 = (1.0 / 4.0) * (-1.0 + r) * (1.0 - s) * (r + s + 1.0)
        N_2 = (1.0 / 4.0) * (1.0 + r) * (1.0 - s) * (-r + s + 1.0)
        N_3 = (1.0 / 4.0) * (1.0 + r) * (1.0 + s) * (r + s - 1.0)
        N_4 = (1.0 / 4.0) * (-1.0 + r) * (1.0 + s) * (r - s + 1.0)
        N_5 = (1.0 / 2.0) * (1.0 - r^2) * (1.0 - s)
        N_6 = (1.0 / 2.0) * (1.0 + r) * (1.0 - s^2)
        N_7 = (1.0 / 2.0) * (1.0 - r^2) * (1.0 + s)
        N_8 = (1.0 / 2.0) * (1.0 - r) * (1.0 - s^2)
        return [N_1 N_2 N_3 N_4 N_5 N_6 N_7 N_8]
    elseif interpolation_order == ORDER_THREE::InterpolationOrder
        # TODO [implement higher order bidimensional elements]
        # implement this interpolation order shape functions
        # can be found in section 6.2.1.6 eq 6.11pag 159 of Zienkiewicz et al.
        throw("Tridimensional shape functions not implement.")
    end
end


function integration_formula(a, b, c) 
    return 2 * A * (factorial(a) * factorial(b) * factorial(c)) / factorial(a + b + c + 2)
end


"""
Calculate the integral in the triangle element using the formula for area coordinates.

ref:
equation 6.49 pag 183 Hutton
"""
function calculate_triangle_integral(expression)
    # TODO: fazer aqui com que faca para cada parcela da expression e multiplique pelo fator 
    # da parcela
    a = Symbolics.degree(expression, r)
    b = Symbolics.degree(expression, s)
    c = Symbolics.degree(expression, t)
    return integration_formula(a, b, c)
end


"""
Calculate integration of a expression addends. 
The formula giben in `calculate_triangle_integral` only works for one addend of an expression
so this function iterates each combination of parameters to get the addend of sum 
and then it calculates the integral based on the
"""
function integrate_triangle(expression)
    # the maximum degrees presented in the expression
    r_max_degree = Symbolics.degree(expression, r)
    s_max_degree = Symbolics.degree(expression, s)
    t_max_degree = Symbolics.degree(expression, t)

    # ensure the expression is expanded in separeted addends
    expression = Symbolics.simplify(expression, expand=true)

    result = Vector{Num}()
    # crete a set with all possible combinations of parameters with power
    parameters = union(
        Set([r^degree for degree=1:r_max_degree]),
        Set([s^degree for degree=1:s_max_degree]),
        Set([t^degree for degree=1:t_max_degree])
    )
    for current_parameter in parameters
        # iterate the combinations and force all other combinations 
        # different of current_parameter to be zero
        integrand = Symbolics.substitute(
            expression,
            Dict(param => 0.0 for param in setdiff(parameters, current_parameter))
        )
        # calculate the integral
        integral = integration_formula(
            Symbolics.degree(integrand, r),
            Symbolics.degree(integrand, s),
            Symbolics.degree(integrand, t)
        )
        # remove the terms with parameters replacing them by one
        # in order to get only the coefficient multiplied by the parameters
        coeff = Symbolics.substitute(
            integrand,
            Dict(r => 1.0, s => 1.0, t => 1.0)
        )
        push!(coeff * integral)
    end
    return sum(result)
end



# TODO [review quadrature options] 
# - take a look in the tables 6.3 pag 181 and 6.4 Zienkiewicz et al.
#   and other ways of positions/weights
"""
Get the quadrature positions and weights. It can be used for any parameter (r, s or t)

ref: 
table 6.1 pag 207 Hutton
table 3.3 pag 65 Zienkiewicz et al.
https://en.wikipedia.org/wiki/Gaussian_quadrature
"""
function get_quadrature_positions(interpolation_order)
    if interpolation_order == 1
        positions = [0.0]
        weights = [2.0]
    elseif interpolation_order == 2
        positions = [1.0 / sqrt(3), -1.0 / sqrt(3)]
        weights = [1.0, 1.0]
    elseif interpolation_order == 3
        positions = [0.0, sqrt(0.6), -sqrt(0.6)]
        weights = [8.0 / 9.0, 5.0 / 9.0, 5.0 / 9.0]
    # NOTE: there is a difference between the table of Hutton and one in Zienkiewicz et al.
    #       for this interpolation order. The Hutton one is used here.
    elseif interpolation_order == 4
        positions = [0.339981043583856, -0.339981043583856, 0.861136311590453, -0.861136311590453]
        weights = [0.652145154862526, 0.652145154862526, 0.347854845137454, 0.347854845137454]
    else
        throw("Not supported interpolation order $(interpolation_order).")
    end
    return QuadratureParameters(positions, weights)
end


# TODO [implement segment elements]
# TODO [implement three dimensional elements]
# - add calculations gauss quadrature for uni- and tridimensional problem
"""
Calculate the Gauss-Legendre Quadrature given a expression.
The expression can be the integrand, W is the vector of weights,
r_pos and s_pos are the vector of positions in r and s to evaluate the quadrature.
These values come from the table 6.1 (pag 207) Hutton
"""
function calculate_gauss_quadrature(expression, r_params::QuadratureParameters, s_params::QuadratureParameters) 
    f(i, j) = substitute(expression, Dict(r => r_params.positions[i], s => s_params.positions[j]))
    return sum([
        r_params.weights[i] * s_params.weights[j] * f(i, j)
        for i in range(1, length(r_params.weights)), j in range(1, length(s_params.weights))
    ])
end


# reproduce the example 6.8 of Hutton
# TODO: move the tests to separeted module in unit test folder
r_params = get_quadrature_positions(2)
s_params = get_quadrature_positions(2)
expr = (r^3 - 1.0) * (s - 1)^2
#@test calculate_gauss_quadrature(expr, r_params, s_params) ≈ -5.33333333333

# TODO [implement segment elements]
# reproduce example 3.3 of Zienkiewicz et al. to validate the integration method for segment element

# reproduce the example 7.4 of Hutton pag 243
N = get_quadrilateral_shape_functions(ORDER_ONE::InterpolationOrder)
∂N_∂r = map(N_i -> expand_derivatives(∂_∂r(N_i)), N)
∂N_∂s = map(N_i -> expand_derivatives(∂_∂s(N_i)), N)
#@test (∂N_∂r' * ∂N_∂r)[1, 1] ≈ 1/3 
#@test (∂N_∂s' * ∂N_∂s)[1, 1] ≈ 1/3 
#@test (N' * N)[1, 1] ≈ 4/9 


# TODO [implement segment elements]
# TODO [implement three dimensional elements]
# - add calculations for the jacobian for uni- and tridimensional problem
""" 
Calculate the Jacobian to change variables of equations from 
a global position system to a local position system.
`positions_x` and `positions_y` (global system) are the points used for the jacobian

equation 9.68 pag 348 Hutton
 x = sum(i=1, m) [N_i(r, s) * x_i]
 y = sum(i=1, m) [N_i(r, s) * y_i]
Jacobian eq 9.73 pag 349 (for two parameters i.e. 2D element)
 J = [∂x/∂r ∂y/∂r;
      ∂x/∂s ∂y/∂s]
"""
function calculate_jacobian(N, positions_x, positions_y)
    # dot used here just to simplify the product and summation operation sequency
    x = dot(N, positions_x)
    y = dot(N, positions_y)
    # need to transpose to keep same positions as the reference text
    return transpose(Symbolics.jacobian([x, y], [r, s]))
end

# example 9.3 pag 352 Hutton
J = calculate_jacobian(N, [1.0, 2.0, 2.25, 1.25], [0, 0, 1.5, 1.0])
#@test isequal(J[1, 1], 0.25(1.0 + s) + 0.25(1.0 - s))
#@test isequal(J[1, 2], 0.125(1.0 + s))
#@test isequal(J[2, 1], 0.0625(1.0 + r) + 0.0625(1.0 - r))
#@test isequal(J[2, 2], 0.375(1.0 + r) + 0.25(1.0 - r))


"""
Calculate the interpolation order based on the order of integrand, for Gauss-Legendre Quadrature.
It uses the relation `2m - 1 = polinomial_order` to calculate the interpolation order `m`
and round integer up (ceil) if fractional value is obtained.
`coordinate` is the parameter r, s, t 
"""
function get_interpolation_order(expression, coordinate)
    polinomial_order = Symbolics.degree(expression, coordinate)
    return ceil(0.5 * (polinomial_order + 1))
end

#@test get_interpolation_order((1.0 + s) * (1.0 + s), s) == 2
#@test get_interpolation_order((1.0 + s) * (1.0 - r) + (2.0 - r)^3, r) == 3