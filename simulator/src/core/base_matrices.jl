# ref: 
# "The Characteristic Based Split (CBS) scheme for laminar and turbulent
# incompressible flow simulations"
# Chun-Bin Liu Thesis Appendix A and B



# directions 
@variables x1, x2, x3
# density, viscosity, gravity, sound velocity, thermal coefficient
@variables ρ, μ, g, c, k
# fractions of real timestep
@variables θ_1, θ_2
# time step interval
@variables Δt

# diferencials for the 3 directions
∂_∂x1 = Differential(x1)
∂_∂x2 = Differential(x2)
∂_∂x3 = Differential(x3)



# For the linear triangular element
# N must be a matrix 1xn
# @assert size(N, 1) == 1, "The size of the shape vector must be 1xn."
# @assert size(u, 2) == 1, "The size of the shape vector must be nx1."
# @assert size(p, 2) == 1, "The size of the shape vector must be nx1."
# @assert size(ρ, 2) == 1, "The size of the shape vector must be nx1."



"""
Calculate the gradient operation based on dimension of the problem.

# example (calculate C_u)
dimension = 2
matrix = [
    N_1*u_1  N_2*u_1  N_3*u_1;
    N_1*u_2  N_2*u_2  N_3*u_2
]

# result size = (1, 3)
result =  [
    Differential(x1)(N_1*u_1) + Differential(x2)(N_1*u_2)
    Differential(x2)(N_2*u_2) + Differential(x1)(N_2*u_1)
    Differential(x2)(N_3*u_2) + Differential(x1)(N_3*u_1)
]
"""
function grad(matrix, dimension=2)
    ∇ = [∂_∂x1, ∂_∂x2, ∂_∂x3]
    result = sum([∂_∂xi.(matrix[i, :]) for (i, ∂_∂xi) in enumerate(∇[1:dimension])])
    return reshape(result, (1, size(matrix, 2)))
end


function strain_operator(N, dimension=2)
    if dimension == 2 
        S = [
            ∂_∂x1 0; 
            0 ∂_∂x2;
            ∂_∂x2 ∂_∂x1;
        ]
    elseif dimension == 3
        S = [
            ∂_∂x1 0 0; 
            0 ∂_∂x2 0;
            0 0 ∂_∂x3;
            ∂_∂x2 ∂_∂x1 0;
            0 ∂_∂x3 ∂_∂x2;
            ∂_∂x3 0 ∂_∂x1;
        ]
    end
    # TODO: do operation with N
    return []
end


################
## integrands ##
################
# TODO: build the functions from symbolics 
# TODO: check all parameters that should be passed during the simulation (e.g. velocities, temperatures, pressures, etc.)
#       and parameters that should be passed when build the functions (such as N)
# TODO: check all grad operands as N (vector) if the dimensions match
#       in this case create another grad function to operate over vectors like N and
#       check how these should operate for operations in forcing vectors like f, f_s, f_p, f_e
## step 1 matrice ##
M_u(N_u) = N_u' * N_u

C_u(N_u, u) = N_u' * grad(u * N_u)

function K_τ(N_u, dimension)
    B(N_u) = strain_operator(N_u)
    if dimension == 2 
        I_o = Diagonal([2.0, 2.0, 1.0])
        m = [1.0, 1.0, 0.0]
    elseif dimension == 3
        I_o = Diagonal([2.0, 2.0, 2.0, 1.0, 1.0, 1.0])
        m = [1.0, 1.0, 1.0, 0.0, 0.0, 0.0]
    end
    return B(N_u)' * μ * (I_o - (2.0 / 3.0) * (m * m')) * B(N_u)
end

# TODO: remember to check dimension of g vector here...
# remember these two are together as f = int(f(N) dΩ) + int(f(N, t) dΓ) 
# see it eq 3.52
f(N_u) = N_u' * ρ * g
f(N_u, t) = N_u' * t

K_u(N_u, u) = grad(u * N_u)' * grad(u * N_u)

# TODO: remember to check dimension of g vector here...
f_s(N_u, u) = -(1 / 2) * grad(u * N_u)' * ρ * g


## step 2 matrices ##
H(N_p) = grad(N_p)' * grad(N_p)

# TODO: check if the notation with superscript n is just to represent time step (1 / c^2)^n 
M_p(N_p) = (1 / c^2) * N_p' * N_p

G(N_p, N_u) = grad(N_p)' * N_u

# TODO: check if the notation with superscript n in Ũ^n
# U is Ũ^n
# ΔU is ΔŨ*  
# p is p^(n + θ_2)
# see the eq. 3.57
f_p(N_p, n, U, ΔU, p) = N_p' * n' * (U + θ_1 * (ΔU - Δt * grad(p)))


## step 3 matrices ##
P(N_u, N_p) = grad(u * N_u)' * grad(N_p)


## step 4 matrices ##
M_E(N_E) = N_E' * N_E

C_E(N_E) = N_E' * grad(u * N_E)

C_p(N_E, N_p) = N_E' * grad(u * N_p)

K_T(N_E, N_T) = grad(u * N_E)' * k * grad(u * N_T)

function K_τE(N_u, u_av, dimension)
    B(N_u) = strain_operator(N_u)
    if dimension == 2 
        I_o = Diagonal([2.0, 2.0, 1.0])
        m = [1.0, 1.0, 0.0]
    elseif dimension == 3
        I_o = Diagonal([2.0, 2.0, 2.0, 1.0, 1.0, 1.0])
        m = [1.0, 1.0, 1.0, 0.0, 0.0, 0.0]
    end
    return B(N_u)' * μ * u_av * (I_o - (2.0 / 3.0) * (m * m')) * B(N_u)
end

K_uE(N_E) = -(1 / 2) * grad(u * N_E)' * grad(N_E)

K_up(N_E, N_p) = -(1 / 2) * grad(u * N_E)' * grad(N_p)

# TODO: check superscript for t^p
f_e(N_E, n, t, u, T) = N_E' * n' * (t * u + k * grad(T))
