"""
references:

Fundamentals of Finite Element Analysis - Hutton (2004) cap 6
The Finite Element Method - Its basis and fundamentals - Zienkiewicz et al. (7nd ed) cap 6
Fundamentals of the Finite Element Method for Head and Mass Transfer - Nithiarasu & Lewis, Seetharamu (2nd ed) cap 7
"""

struct QuadratureParameters
    positions::Vector{Float64}
    weights::Vector{Float64}
end

# TODO [review shape functions]
# - add other options of interpolation (see Pascal triangle polynomials) to be used
#   as basis for the deduction of other shape functions with another number of points
#   e.g. "mini" triangle element

"""
Get the triangle shape function based on interpolation order.

Here the parameters r, η, ζ correspond to the area coordinates of triangle
r => L_1
η => L_2
ζ => L_3
"""
function get_triangle_shape_functions(interpolation_order::InterpolationOrder)
    # equation 6.41 cap 6 Hutton
    if interpolation_order == ORDER_ONE::InterpolationOrder
        N_1 = 1.0 - ξ - η
        N_2 = ξ
        N_3 = η
        return [N_1 N_2 N_3]
        # equation 6.46 cap 6 Hutton
    elseif interpolation_order == ORDER_TWO::InterpolationOrder
        N_1 = ξ * (2.0 * ξ - 1.0)
        N_2 = η * (2.0 * η - 1.0)
        N_3 = ζ * (2.0 * ζ - 1.0)
        N_4 = 4.0 * ξ * η
        N_5 = 4.0 * η * ζ
        N_6 = 4.0 * ξ * ζ
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
        N_1 = (1.0 / 4.0) * (1.0 - ξ) * (1.0 - η)
        N_2 = (1.0 / 4.0) * (1.0 + ξ) * (1.0 - η)
        N_3 = (1.0 / 4.0) * (1.0 + ξ) * (1.0 + η)
        N_4 = (1.0 / 4.0) * (1.0 - ξ) * (1.0 + η)
        return [N_1 N_2 N_3 N_4]
        # this is the eight node version 
        # eq 6.59 cap 6 pag 186 Hutton
    elseif interpolation_order == ORDER_TWO::InterpolationOrder
        N_1 = (1.0 / 4.0) * (-1.0 + ξ) * (1.0 - η) * (ξ + η + 1.0)
        N_2 = (1.0 / 4.0) * (1.0 + ξ) * (1.0 - η) * (-ξ + η + 1.0)
        N_3 = (1.0 / 4.0) * (1.0 + ξ) * (1.0 + η) * (ξ + η - 1.0)
        N_4 = (1.0 / 4.0) * (-1.0 + ξ) * (1.0 + η) * (ξ - η + 1.0)
        N_5 = (1.0 / 2.0) * (1.0 - ξ^2) * (1.0 - η)
        N_6 = (1.0 / 2.0) * (1.0 + ξ) * (1.0 - η^2)
        N_7 = (1.0 / 2.0) * (1.0 - ξ^2) * (1.0 + η)
        N_8 = (1.0 / 2.0) * (1.0 - ξ) * (1.0 - η^2)
        return [N_1 N_2 N_3 N_4 N_5 N_6 N_7 N_8]
    elseif interpolation_order == ORDER_THREE::InterpolationOrder
        # TODO [implement higher order bidimensional elements]
        # implement this interpolation order shape functions
        # can be found in section 6.2.1.6 eq 6.11pag 159 of Zienkiewicz et al.
        throw("Tridimensional shape functions not implement.")
    end
end


# TODO [implement segment elements]
# include the 1D versions of this function 
# TODO [implement three dimensional elements]
# include the 3D versions of this function
"""
Calculate the integral in the triangle element using the formula for area coordinates.
    
ref:
equation 6.49 pag 183 Hutton
"""
function integration_formula_2D(a, b, c)
    if a == 0 && b == 0 && c == 0
        return A
    end
    return 2 * A * (factorial(a) * factorial(b) * factorial(c)) / factorial(a + b + c + 2)
end


"""
Calculate integration of an expression terms. This function transforms the expression into a string
and then split the string in the positions of 
This function iterates for each term in the expression and integrate isolated.
"""
function integrate_triangle(expression)
    # do a trick with polynomial expansion from SymbolicsUtils
    # need these auxiliary variables (created with @syms) in order the PolyForm works correctly
    Symbolics.SymbolicUtils.@syms ξ_aux η_aux ζ_aux
    polynomial = Symbolics.SymbolicUtils.PolyForm(
        Symbolics.substitute(
            expression,
            Dict(ξ => ξ_aux, η => η_aux, ζ => ζ_aux)
        )
    )
    integrals = Vector{Num}()

    # workaraound to get the operation multiply if it is only one term to integrate
    # otherwise the arguments will return the factors of term (e.g. -3 * ξ would return -3 and ξ)
    is_unique_term = string(operation(polynomial)) == "*"
    all_polynomial_terms = is_unique_term ? [expression] : Symbolics.SymbolicUtils.arguments(polynomial)

    # integrate the terms of the interpolation polynomial of the integrand expression
    for polynomial_term in all_polynomial_terms
        # substitute back the parameters of the original expression
        # because the degree function must be used in the format suported by Symbolics
        # and the cast BasicSymbolic{Real} to Num here is mandatory
        integrand = Num(
            Symbolics.substitute(
                polynomial_term, Dict(ξ_aux => ξ, η_aux => η, ζ_aux => ζ)
            )
        )

        # remove the parameters in the term replacing them by value one
        # in order to get only the coefficient multiplied by the parameters
        # and then multiply the calculated integral resultant expression
        coefficient = Symbolics.substitute(
            integrand, Dict(ξ => 1.0, η => 1.0, ζ => 1.0)
        )
        integral = coefficient * integration_formula_2D(
            Symbolics.degree(integrand, ξ),
            Symbolics.degree(integrand, η),
            Symbolics.degree(integrand, ζ)
        )
        push!(integrals, integral)
        # TODO [review shape functions]
        # this should be loged
        #println("$integrand ξ=$(Symbolics.degree(integrand, ξ)) η=$((Symbolics.degree(integrand, η))) ζ=$(Symbolics.degree(integrand, ζ)) integral=$integral")
    end
    return sum(integrals)
end


# TODO [review quadrature options] 
# - take a look in the tables 6.3 pag 181 and 6.4 Zienkiewicz et al.
#   and other ways of positions/weights
"""
Get the quadrature positions and weights. It can be used for any parameter (ξ, η or ζ)

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


"""
Calculate the interpolation order based on the order of integrand, for Gauss-Legendre Quadrature.
It uses the relation `2m - 1 = polinomial_order` to calculate the interpolation order `m`
and round integer up (ceil) if fractional value is obtained.
`parameter` is the parameter ξ, η, ζ 
"""
function get_interpolation_order(expression, parameter)
    polinomial_order = Symbolics.degree(expression, parameter)
    return ceil(0.5 * (polinomial_order + 1))
end


# TODO [implement segment elements]
# TODO [implement three dimensional elements]
# - add calculations gauss quadrature for uni- and tridimensional problem
"""
Calculate the Gauss-Legendre Quadrature given a expression.
The expression can be the integrand, W is the vector of weights,
r_pos and s_pos are the vector of positions in ξ and η to evaluate the quadrature.
These values come from the table 6.1 (pag 207) Hutton
"""
function calculate_gauss_quadrature(expression, ξ_params::QuadratureParameters, η_params::QuadratureParameters)
    f(i, j) = substitute(expression, Dict(ξ => ξ_params.positions[i], η => η_params.positions[j]))
    return sum([
        ξ_params.weights[i] * η_params.weights[j] * f(i, j)
        for i in range(1, length(ξ_params.weights)), j in range(1, length(η_params.weights))
    ])
end


# TODO [implement segment elements]
# - reproduce example 3.3 of Zienkiewicz et al. to validate the integration method for segment element
# TODO [implement three dimensional elements]
# - add calculations for the jacobian for tridimensional problem
""" 
Calculate the Jacobian to change variables of equations from 
a global position system to a local position system.
`positions_x` and `positions_y` (global system) are the points used for the jacobian

equation 9.68 pag 348 Hutton
 x = sum(i=1, m) [N_i(ξ, η) * x_i]
 y = sum(i=1, m) [N_i(ξ, η) * y_i]
Jacobian eq 9.73 pag 349 (for two parameters i.e. 2D element)
 J = [∂x/∂r ∂y/∂r;
      ∂x/∂s ∂y/∂s]
"""
function calculate_jacobian(N, positions_x, positions_y)
    # dot product for the sum(N_i * pos_i)
    x = sum([N[i] * positions_x[i] for (i, _) in enumerate(positions_x)])
    y = sum([N[i] * positions_y[i] for (i, _) in enumerate(positions_y)])
    # need to transpose to keep same positions as the reference text
    return transpose(Symbolics.jacobian([x, y], [ξ, η]))
end