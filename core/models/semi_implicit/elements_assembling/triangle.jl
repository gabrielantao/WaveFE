"""
Assemble elemental mass matrix M 
ref: Nithiarasu eq 7.152 pag 208
"""
function assemble_mass_lumped(element::Triangle, parameters::Dict{String, Float64})
    # TODO: it assembles a first order triangle 
    # maybe the type should change depending on interpolation order (e.g. TRIANGLE1, TRIANGLE2, etc.)
    # ref: Nithiarasu eq 7.171 pag 211
    factor = element.area / element.Δt / 3.0
    return diagm([factor, factor, factor])
end


"""Assemble transient mass matrix M"""
function assemble_mass(element::Triangle, parameters::Dict{String, Float64})
    # TODO: it assembles a first order triangle 
    # maybe the type should change depending on interpolation order (e.g. TRIANGLE1, TRIANGLE2, etc.)
    # TODO: check adimensionalization here...
    return (element.area / 12.0 / element.Δt) .* [2.0 1.0 1.0; 1.0 2.0 1.0; 1.0 1.0 2.0]
end


"""
Calculate stiffness matrix K 
ref: Nithiarasu eq 7.158 pag 209
"""
function assemble_stiffness(element::Triangle, parameters::Dict{String, Float64}) 
    return element.Δt * element.area * (element.b * element.b' + element.c * element.c') 
end


"""
Calculate convection matrix C
It depends on velocity so it's updated every time step

ref: Nithiarasu eq 7.153 pag 208
"""
function calculate_momentum_convection(element::Triangle, parameters::Dict{String, Float64})  
        b = element.b
        c = element.c
        # u_1 and u_2 are velocity in x and y direction, 
        # each position of vector is for one node in element 
        # u_1 = [u_1i, u_1j, u_1k, ...]
        # u_2 = [u_2i, u_2j, u_2k, ...]
        u_1 = element.old_values["u_1"]
        u_2 = element.old_values["u_2"]
        u_1_sum = sum(u_1)
        u_2_sum = sum(u_2)
        # ((2.0 * area) * (1 / 24.0)) .* ((u_1_sum .+ u_1) * b' + (u_2_sum .+ u_2) * c') 
        return (element.area / 12.0) .* ((u_1_sum .+ u_1) * b' + (u_2_sum .+ u_2) * c') 
end


"""
Calculate momentum diffusion matrix Km

ref: Nithiarasu eq 7.155 pag 208
"""
function calculate_momentum_diffusion(element::Triangle, parameters::Dict{String, Float64})
    Re = parameters["Re"]
    return  (element.area / Re) .* (element.b * element.b' + element.c * element.c')
end


"""
Calculate stabilization matrix Ks

ref: Nithiarasu eq 7.157 pag 209
"""
function calculate_momentum_stabilization(element::Triangle, parameters::Dict{String, Float64})
    b = element.b
    c = element.c
    # u_1 and u_2 are velocity in x and y direction
    # for each position of vector is for one node in element 
    # u_1 = [u_1i, u_1j, u_1k, ...]
    # u_2 = [u_2i, u_2j, u_2k, ...]
    u_1 = element.old_values["u_1"]
    u_2 = element.old_values["u_2"]
    Ks  = mean(u_1) .* (sum(u_1) .* (b * b') + sum(u_2) .* (b * c'))
    Ks += mean(u_2) .* (sum(u_1) .* (c * b') + sum(u_2) .* (c * c'))
    # ((2.0 * area) * (dt / 2.0) / 6.0) .* Ks
    return ((element.Δt / 2.0) * (element.area / 3.0)) .* Ks
end


"""Assemble elemental RHS for step 1 for both velocities u_1 and u_2"""
function assemble_rhs_step_1(element::Triangle, parameters::Dict{String, Float64})
    # TODO: check forcing vectors in this assembling process
    # Nithiarasu pag 210 eq 7.161, 7.162
    C_e = calculate_momentum_convection(element, parameters)
    Km_e = calculate_momentum_diffusion(element, parameters)
    Ks_e = calculate_momentum_stabilization(element, parameters)
    return Dict(
        "u_1" => -(C_e + Km_e + Ks_e) * element.old_values["u_1"], 
        "u_2" => -(C_e + Km_e + Ks_e) * element.old_values["u_2"]
    )
end


"""
Calculate elemental RHS for step 2 [G1]*{u_1} + [G2]*{u_2} 
NOTE: velocity used inside this function is intermediate velocity
Nithiarasu eq 7.159 and 7.160
"""
function assemble_rhs_step_2(element::Triangle, parameters::Dict{String, Float64})
    # TODO: check forcing vectors in this assembling process
    # Nithiarasu pag 210 eq 7.163
    b = element.b
    c = element.c
    # u_1 and u_2 are velocity in x and y direction
    # for each position of vector is for one node in element 
    # u_1 = [u_1i, u_1j, u_1k, ...]
    # u_2 = [u_2i, u_2j, u_2k, ...]
    # intermediate velocities
    u_1_int = element.values["u_1_int"]
    u_2_int = element.values["u_2_int"]
    # these are last registered results (i.e. last time step result)
    u_1_old = element.old_values["u_1"]
    u_2_old = element.old_values["u_2"]
    Δu_1 = u_1_int - u_1_old
    Δu_2 = u_2_int - u_2_old
    rhs = (element.area / 3.0) * (dot(b, u_1_old) + dot(c, u_2_old))
    rhs = (element.area / 3.0) .* (b .* sum(Δu_1) + c .* sum(Δu_2)) .- rhs
    return Dict("p" => rhs) 
end


"""
Calculate elemental RHS for step 3
NOTE: velocity used inside this function is intermediate velocity
Nithiarasu eq 7.159 and 7.160
"""
function assemble_rhs_step_3(element::Triangle, parameters::Dict{String, Float64})
    b = element.b
    c = element.c
    # u_1 and u_2 are velocity in x and y direction
    # for each position of vector is for one node in element 
    # u_1 = [u_1i, u_1j, u_1k, ...]
    # u_2 = [u_2i, u_2j, u_2k, ...]
    # pressure
    p = element.values["p"]
    p_old = element.old_values["p"]
    # these are last registered results (i.e. last time step result)
    u_1_old = element.old_values["u_1"]
    u_2_old = element.old_values["u_2"]
    # calculate gradients and use mean velocity for computations
    grad_1 = (element.area / 3.0) * dot(b, p)
    grad_2 = (element.area / 3.0) * dot(c, p)
    grad_1_old = (element.area * element.Δt / 2.0) * dot(b, p_old)
    grad_2_old = (element.area * element.Δt / 2.0) * dot(c, p_old)
    return Dict(
        "u_1" => -(grad_1 .+ (b .* mean(u_1_old) + c .* mean(u_2_old)) .* grad_1_old), 
        "u_2" => -(grad_2 .+ (b .* mean(u_1_old) + c .* mean(u_2_old)) .* grad_2_old)
    )
end