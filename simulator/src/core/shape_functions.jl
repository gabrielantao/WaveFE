"""
references:

Fundamentals of Finite Element Analysis - Hutton (2004) cap 6
The Finite Element Method - Its basis and fundamentals - Zienkiewicz et al. (7nd ed) cap 6
Fundamentals of the Finite Element Method for Head and Mass Transfer - Nithiarasu & Lewis, Seetharamu (2nd ed) cap 7
"""

using Symbolics


# for the linear segment
#N = Symbolics.variables(:N, 1:2)
#ϕ = Symbolics.variables(:ϕ, 1:2)
#M = N * N'


# for the linear triangle
#@variables x, L
#N_1 = 1 - x / L
#N_2 = x / L
#D = Differential(x)

# variables for square element
@variables r, s


# TODO: add calculations for other dimensions
"""
Calculate the Gauss-Legendre Quadrature given a expression.
The expression can be the integrand, W is the vector of weights,
r_pos and s_pos are the vector of positions in r and s to evaluate the quadrature.
These values come from the table 6.1 (pag 207) and table 6.2 (pag 212) Hutton
"""
function calculate_gauss_quadrature(expression, W, r_pos, s_pos) 
    f(i, j) = substitute(expression, Dict(r => r_pos[i], s => s_pos[j]))
    return sum([
        W[i] * W[j] * f(i, j)
        for i in 1:2, j in 1:2
    ])
end

# reproduce the example 6.8 of Hutton
# TODO: move the tests to separeted module in unit test folder
# TODO: put the table of values for quadrature and shape functions somewhere
W = [1.0, 1.0]
r_pos = [sqrt(3)/3, -sqrt(3)/3]
s_pos = [sqrt(3)/3, -sqrt(3)/3]
expr = (r^3 - 1.0) * (s - 1)^2
println(
    calculate_gauss_quadrature(expr, W, r_pos, s_pos)
)
#@test calculate_gauss_quadrature(expr, W, r_pos, s_pos) ≈ -5.33333333333


# reproduce the example 7.4 of Hutton pag 232
# square element:
# - unit square the 2a = 2b = 1 and 
# - dA = dx*dy = a*b*dr*ds (jacobian transformation to get this)
∂_∂s = Differential(s)
∂_∂r = Differential(r)

N_1 = (1.0 / 4.0) * (1.0 - r) * (1.0 - s)
N_2 = (1.0 / 4.0) * (1.0 + r) * (1.0 - s)
N_3 = (1.0 / 4.0) * (1.0 + r) * (1.0 + s)
N_4 = (1.0 / 4.0) * (1.0 - r) * (1.0 + s)
N = [N_1 N_2 N_3 N_4]

∂N_∂r = map(N_i -> expand_derivatives(∂_∂r(N_i)), N)
∂N_∂s = map(N_i -> expand_derivatives(∂_∂s(N_i)), N)

#@test (∂N_∂r' * ∂N_∂r)[1, 1] ≈ 1/3 
#@test (∂N_∂s' * ∂N_∂s)[1, 1] ≈ 1/3 
#@test (N' * N)[1, 1] ≈ 4/9 


""" 
Calculate the Jacobian to change variables of equations from 
a global position system to a local position system.

equation 9.68 pag 348 Hutton
 x = sum(i=1, m) [N_i(r, s) * x_i]
 y = sum(i=1, m) [N_i(r, s) * y_i]
Jacobian eq 9.73 pag 349 (for two parameters i.e. 2D element)
 J = [∂x/∂r ∂y/∂r;
      ∂x/∂s ∂y/∂s]
"""
function calculate_jacobian(N, x_points, y_points)
    # dot used here just to simplify the product and summation operation sequency
    x = dot(N, x_points)
    y = dot(N, y_points)
    # need to transpose to keep same positions as the reference text
    return transpose(Symbolics.jacobian([x, y], [r, s]))
end

# example 9.3 pag 352 Hutton
J = calculate_jacobian(N, [1.0, 2.0, 2.25, 1.25], [0, 0, 1.5, 1.0])
#@test isequal(J[1, 1], 0.25(1.0 + s) + 0.25(1.0 - s))
#@test isequal(J[1, 2], 0.125(1.0 + s))
#@test isequal(J[2, 1], 0.0625(1.0 + r) + 0.0625(1.0 - r))
#@test isequal(J[2, 2], 0.375(1.0 + r) + 0.25(1.0 - r))


# TODO:
# based on the order of integrand calculate 2m -1 = order_polinomial
# rounded integer up if fractional value
# use the Symbolics.degree(expr, variable) to get the maximum degree in the order_polinomial
