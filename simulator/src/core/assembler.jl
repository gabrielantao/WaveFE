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

    function Assembler(lhs_type::MatrixType = DENSE::MatrixType)
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
            assembler.lhs_type == DIAGONAL::MatrixType ? DIAGONAL::MatrixType : DENSE::MatrixType, 
            element_container.nodes_per_element
        )
        for element in get_elements(element_container)
            for (i, j) in index_iterator
                push!(
                    all_indices_pairs, (element.connectivity[i], element.connectivity[j])
                )
            end
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
    if lhs_type == DIAGONAL::MatrixType
        return Iterators.zip(1:nodes_per_element, 1:nodes_per_element)
    elseif lhs_type == SYMMETRIC::MatrixType  
        indices = Iterators.product(1:nodes_per_element, 1:nodes_per_element)
        # return upper (and diagonal) indices of matrix
        return Iterators.filter(index -> index[1] <= index[2], indices)
    elseif lhs_type == DENSE::MatrixType
        return Iterators.product(1:nodes_per_element, 1:nodes_per_element)
    else 
        throw("Not implemented special matrix type to be assembled")
    end
end
