# TODO [implement validations and input versioning]
## implement logic validators here
function validate_simulation_data(simulation_data)
end


# TODO [implement validations and input versioning]
## implement logic validators here
function validate_domain_conditions_data(domain_conditions_data)
    # TODO: do a logical validation here to ensure :
    # - all group names are valid names
    # - all variables are valid variable names (just alert if not)
    # - valid condition type number (raise by now if is not first type not implemented yet)
    # - alert duplicated conditions and pop from imported data
    # - break if there are two conditions with same (named group + variable + condition type)
    #   message ambiguous or duplicated
    # - for now only allow first type condition (value conition) for initial values
    #   change this for validation process
end

