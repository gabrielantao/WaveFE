# Generate conditions file for the backward facing step
using DelimitedFiles
using TOML

# import the data with velocities at x=0.0 reference:
# Denham, M.K. and Patrick, M.A. (1974) 
# Laminar Flow over a Downstream-Facing, Step in a Two-Dimensional Flow Channel. 
# Transactions of the Institution of Chemical Engineers, 52, 361-367. 
inlet_points = readdlm(
    joinpath("reference", "result_x_0_00.csv"), ',', Float64, '\n', skipstart=1
)

# create the conditions output data
output_data = Dict(
    "general" => Dict(
        "version" => "1.0", 
        "description" => "Backward-facing step case 2D"
    ),
    "initial" => [],
    "boundary" => [],
)

# define initial and boundary values
for condition_class in ["initial", "boundary"]
    # define values for the inlet conditions
    for index = 1:19
        # the csv is sorted but the mesh is descending order, so must do 20-index
        push!(
            output_data[condition_class], 
            Dict(
                "description" => "$(condition_class) value for inlet point $(index)", 
                "group_name" => "inlet_$index",
                "value" => 1.0,#inlet_points[20-index, 2], 
                "unknown" => "u_1", 
            )
        )
        push!(
            output_data[condition_class], 
            Dict(
                "description" => "$(condition_class) value for inlet point $(index)",
                "group_name" => "inlet_$index",
                "value" => 0.0, 
                "unknown" => "u_2", 
            )
        )
    end

    # define values for no-slip conditions
    push!(
        output_data[condition_class], 
        Dict(
            "description" => "$(condition_class) value for no-slip walls", 
            "group_name" => "no-slip",
            "value" => 0.0, 
            "unknown" => "u_1", 
        )
    )
    push!(
        output_data[condition_class], 
        Dict(
            "description" => "$(condition_class) value for no-slip walls",
            "group_name" => "no-slip",
            "value" => 0.0, 
            "unknown" => "u_2", 
        )
    )

    # define values for the outlet
    push!(
        output_data[condition_class], 
        Dict(
            "description" => "$(condition_class) value for the outlet",
            "group_name" => "outlet",
            "value" => 0.0001, 
            "unknown" => "p", 
        )
    )
end

# define condition type
for condition in output_data["boundary"]
    condition["condition_type"] = 1
end

# export the file
open("conditions.toml", "w") do io
    TOML.print(io, output_data)
end