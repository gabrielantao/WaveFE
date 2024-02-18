module ModuleSemiImplicit

using LinearAlgebra
using SparseArrays
using Preconditioners
using IterativeSolvers

# implementation for the mesh and domain conditions
# to be used by this model
include("../../common.jl")
include("../../mesh/mesh.jl")
include("../../domain_conditions.jl")

# include assembling functions
include("./elements_assembling/segment.jl")
include("./elements_assembling/triangle.jl")
include("./elements_assembling/quadrilateral.jl")
include("../../unknowns_handler.jl")


"""Additional parameters from the input file"""
struct ModelSemiImplicitParameters <: ModelParameters
    transient::Bool
    use_lumped_mass::Bool
    safety_dt_factor::Float64
    adimensionals::Dict{String, Float64}
end


"""
Semi-implicit model
TODO: include description here ....
"""
struct ModelSemiImplicit
    name::String
    mesh::Mesh
    domain_conditions::DomainConditions
    unknowns_handler::Vector{String}
    equations::Vector{ModelEquation}
    additional_parameters::ModelSemiImplicitParameters

    function ModelSemiImplicit(input_data, simulation_parameters)
        unkowns_handler = load_unkowns_handler(input_data, simulation_parameters)
        mesh = load_mesh(input_data, simulation_parameters)
        domain_conditions = load_domain_conditions(input_data)

        # configure the additional parameters
        transient = simulation_parameters["simulation"]["transient"]
        use_lumped_mass = !transient
        safety_dt_factor = simulation_parameters["simulation"]["safety_dt_factor"]
        adimensionals = simulation_parameters["parameter"]
        additional_parameters = ModelSemiImplicitParameters(
            use_lumped_mass,
            safety_dt_factor,
            adimensionals
        )

        # TODO: configure here the equations...
        solver = load_solver(simulation_parameters)
        mass_lhs_diagonal = use_lumped_mass
        # TODO: implement here...
        # step 1 equation
        # assembler = Assembler(
        #     mass_lhs_diagonal, 
        #     mass_lhs_diagonal
        # )
        #assemble_indices!(assembler, mesh)
        # equation_1 = ModelEquation(
        #     "step 1",
        #     ["u_$i" for i in Int(mesh.dimension)]
        #     assembler,
        #     solver,
        # )


        new(
            "CBS Semi-implicit", 
            mesh,
            domain_conditions,
            unkowns_handler, 
            equations,
            additional_parameters
        )
    end
end


"""Run one iteration for this model"""
function run_iteration(model::ModelSemiImplicit)
    # check if it must update the LHS matrix only if the mesh has moved its nodes
    must_update_lhs = mesh.nodes.moved
 
    # update elements internal data
    if mesh.nodes.moved
        update_elements!(
            mesh,
            nodes_container,
            unknowns_handler,
            model_parameters
        )
    end
    
    # update the unknowns by coping current values to the old values
    refresh_values!(model.unknowns_handler)

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
    mesh.nodes.move!()
    
    # TODO: it should check if it is diverging to abort simulation
    check_unknowns_convergence!(model.unknowns_handler)
end


end # module