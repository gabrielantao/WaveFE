"""Assemble the global matrix for LHS"""
function assemble_global_lhs(
    equation::Equation,
    mesh::Mesh,
    unknowns_handler::UnknownsHandler,
    model_parameters::ModelParameters
)  
    # preallocate the sparse matrix with zeros
    lhs = sparse(
        equation.base.assembler.lhs_indices_i, 
        equation.base.assembler.lhs_indices_j, 
        zeros(length(equation.base.assembler.lhs_indices_i))
    )
    # do the assembling of global matrix for each element container in the mesh
    for element_container in WaveCore.get_containers(mesh.elements)
        index_iterator = WaveCore.get_local_indices_iterator(
            equation.base.assembler.lhs_type, 
            element_container.nodes_per_element
        )
        for element in WaveCore.get_elements(element_container)
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
    # TODO [review symmetric matrix assembling]
    # for now its assembling symmetric both sides off-diagonal (upper and lower)
    # of sparse matrix. This should be reviewed in the future to use other types of
    # sparse that don't waste space (e.g. package SparseMatrixCRC.jl) 
    # for now just copy the values of upper side of matrix to the lower side
    if equation.base.assembler.lhs_type == WaveCore.SYMMETRIC::MatrixType
        for (i, j) in zip(
            equation.base.assembler.lhs_indices_i, equation.base.assembler.lhs_indices_j
        )
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
    total_nodes = WaveCore.get_total_nodes(mesh.nodes)
    rhs = Dict(unknown => zeros(total_nodes) for unknown in equation.base.solved_unknowns)
    # do the assembling of global matrix for each element container in the mesh
    for element_container in WaveCore.get_containers(mesh.elements)
        for element in WaveCore.get_elements(element_container)
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