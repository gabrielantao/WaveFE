"""
references:

Fundamentals of Finite Element Analysis - Hutton (2004) cap 6
The Finite Element Method - Its basis and fundamentals - Zienkiewicz et al. (7nd ed) cap 6
Fundamentals of the Finite Element Method for Head and Mass Transfer - Nithiarasu & Lewis, Seetharamu (2nd ed) cap 7
"""

using Symbolics


struct QuadratureParameters
    positions::Vector{Float64}
    weights::Vector{Float64}
end


# variables for square element
# TODO: think if it should use r, s, t or ξ, η, ζ as notation for these functions
@variables r, s
∂_∂s = Differential(s)
∂_∂r = Differential(r)


# TODO: implement this to get the triangle shape functions
function get_triangle_shape_functions(interpolation_order::InterpolationOrder)
    if interpolation_order == ORDER_ONE::InterpolationOrder
        #...
    elseif interpolation_order == ORDER_TWO::InterpolationOrder
        #...
    elseif interpolation_order == ORDER_THREE::InterpolationOrder
        throw("Tridimensional shape functions not implement.")
    end
end


"""Get the quadrilateral shape function based on interpolation set."""
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
        throw("Tridimensional shape functions not implement.")
    end
end


# TODO [review quadrature options] 
#   take a look in the tables 6.3 pag 181 and 6.4 Zienkiewicz et al.
#   and other ways of positions/weights 
"""
Get the quadrature positions and weights. It can be used for any parameter (r, s or t)
ref: table 6.1 pag 207 Hutton
"""
function get_quadrature_positions(interpolation_order)
    if interpolation_order == 1
        positions = [0.0]
        weights = [2.0]
    elseif interpolation_order == 2
        # sqrt(3.0) / 3.0
        positions = [0.577350269189626, -0.577350269189626]
        weights = [1.0, 1.0]
    elseif interpolation_order == 3
        positions = [0.0, 0.774596669241483, -0.774596669241483]
        weights = [0.774596669241483, 0.555555555555556, 0.555555555555556]
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
println(
    calculate_gauss_quadrature(expr, r_params, s_params)
)
#@test calculate_gauss_quadrature(expr, W, r_pos, s_pos) ≈ -5.33333333333


# reproduce the example 7.4 of Hutton pag 232
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