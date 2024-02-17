module ModelSemiImplicit

struct Model
    name::String
    unknowns_handler::Vector{String}
    equations::Vector{ModelEquation}
    use_lumped_mass::Bool
end


function setup_model()
end

# TODO: get the logger here
function run_iteration(
    model::Model,
    mesh::Mesh,
    domain_conditions::DomainConditions,
    #output_manager,
    #logger,
    simulation_parameters::Dict{String, Float64}
    step_number::Int32
)
    # check if it must update the LHS matrix only if the mesh has moved its nodes
    must_update_lhs = mesh.nodes.moved
 
    # update elements internal data
    if mesh.nodes.moved
        update_elements(mesh, simulation_parameters)
    end
    
    # update the unknowns by coping current values to the old values
    update_unknowns_old(model.unknowns_handler)

    # solve the sequence of registered equations for each variable
    for equation in model.equations
        solve!(
            equation,
            mesh,
            model.unknowns_handler,
            domain_conditions,
            must_update_lhs
        )
    end

    # do the movement for the nodes
    mesh.nodes.move()
    
    # return if the current iteration converged
    # TODO: it should check if it is diverging to abort simulation
    return check_convergence(model.unknowns_handler)
end


end # module