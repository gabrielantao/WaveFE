export Assembler
export MatrixType

@enum MatrixType begin
    DIAGONAL = 1
    SYMMETRIC = 2
    DENSE = 3
end


"""It holds data for the assembler"""
mutable struct Assembler
    # it represents the type of LHS matrix assembled
    lhs_type::MatrixType
    # indices of LHS matrix to be used to preallocate 
    lhs_indices_i::Vector{Int64}
    lhs_indices_j::Vector{Int64}

    function Assembler(lhs_type::MatrixType=DENSE)
        new(
            lhs_type,
            Int64[],
            Int64[],
        )
    end
end


"""This function assigns the indices to preallocate an empty assembler LHS"""
function update_assembler_indices!(assembler::Assembler, mesh::Mesh)
    all_indices_pairs = Set{Tuple{Int64, Int64}}()
    for element_container in get_containers(mesh.elements)
        # TODO [review symmetric matrix assembling]:
        # for now its assembling symmetric both sides off-diagonal (upper and lower)
        # of sparse matrix. This should be reviewed in the future to use other types of
        # sparse that don't waste space (e.g. package SparseMatrixCRC.jl) 
        index_iterator = get_local_indices_iterator(
            assembler.lhs_type == DIAGONAL ? DIAGONAL : DENSE, 
            element_container.nodes_per_element
        )
        for element in element_container
            push!(
                indices,
                [
                    (element.connectivity[i], element.connectivity[j])
                    for (i, j) in index_iterator
                ]
            )
        end
    end
    # ensure the vector are empty then fill them with the indices values
    assembler.lhs_indices_i = Int64[]
    assembler.lhs_indices_j = Int64[]
    for (i, j) in collect(all_indices_pairs)
        push!(assembler.lhs_indices_i, i)
        push!(assembler.lhs_indices_j, j)
    end
end


"""Auxiliary function to get local indices to the assembler"""
function get_local_indices_iterator(lhs_type::MatrixType, nodes_per_element::Int64)
    if lhs_type == DIAGONAL
        return Iterators.zip(1:nodes_per_element, 1:nodes_per_element)
    elseif lhs_type == SYMMETRIC  
        indices = Iterators.product(1:nodes_per_element, 1:nodes_per_element)
        # return upper (and diagonal) indices of matrix
        return Iterators.filter(index -> index[1] <= index[2], indices)
    elseif lhs_type == DENSE
        return Iterators.product(1:nodes_per_element, 1:nodes_per_element)
    else 
        throw("Not implemented special matrix type to be assembled")
    end
end


"""Assemble the global matrix for LHS"""
function assemble_global_lhs(
    equation::Equation,
    mesh::Mesh,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)  
    # preallocate the sparse matrix with zeros
    lhs = sparse(
        equation.assembler.lhs_indices_i, 
        equation.assembler.lhs_indices_j, 
        zeros(length(equation.assembler.lhs_indices_i))
    )
    # do the assembling of global matrix for each element container in the mesh
    for element_container in get_containers(mesh.elements)
        index_iterator = get_local_indices_iterator(
            equation.assembler.lhs_type, 
            element_container.nodes_per_element
        )
        for element in element_container
            assembled_local_lhs = assemble_element_lhs(
                equation, 
                element, 
                unknowns_handler,
                model_parameters
            )
            for (i, j) in index_iterator
                global_i = element.connectivity[i]
                global_j = element.connectivity[j]
                lhs[global_i, global_j] += assembled_local_lhs[i, j]
            end
        end
    end
    # TODO [review symmetric matrix assembling]: 
    # for now its assembling symmetric both sides off-diagonal (upper and lower)
    # of sparse matrix. This should be reviewed in the future to use other types of
    # sparse that don't waste space (e.g. package SparseMatrixCRC.jl) 
    # for now just copy the values of upper side of matrix to the lower side
    if equation.assembler.lhs_type == SYMMETRIC
        for (i, j) in zip(equation.assembler.lhs_indices_i, equation.assembler.lhs_indices_j)
            if i < j
                lhs[j, i] = lhs[i, j]
            end
        end
    end
    return lhs
end


"""Assemble RHS vectors for the elements of the mesh"""
function assemble_global_rhs( 
    equation::Equation,
    mesh::Mesh,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)
    # preallocate the assembled rhs vectors
    # TODO [general performance improvements]
    ## maybe this should use NamedTuple (or just tuple) instead of dict
    rhs = Dict(unknown => zeros(mesh.nodes.total_nodes) for unknown in equation.solved_unknowns)
    # do the assembling of global matrix for each element container in the mesh
    for element_container in get_containers(mesh.elements)
        for element in element_container
            assembled_local_rhs = assemble_element_rhs(
                equation,
                element, 
                unknowns_handler,
                model_parameters
            )
            # TODO [general performance improvements]
            ## review if the best is use a named tuple or something else
            for unknown in keys(assembled_local_rhs)
                for i in range(1, element_container.nodes_per_element)
                    global_i = element.connectivity[i]
                    rhs[unknown][global_i] += assembled_local_rhs[unknown][i]
                end
            end
        end
    end
    return rhs
end