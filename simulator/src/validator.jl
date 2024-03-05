# TODO [implement validations and input versioning]
## implement logic validators here
## transcribe this original Python code
function validate_simulation_data(simulation_data)
    # - check it has all unknowns in the tolerance list

    # logger.info("doing logical validation of the simulation.toml")
    # # check if solver options are correct
    # if self.simulation_data["solver"]["name"] not in self.SOLVER_OPTIONS:
    #     logger.error(
    #         "The simulator do not have the solver %s available.\nThe list of available solvers is: %s",
    #         self.simulation_data["solver"]["name"],
    #         ", ".join(self.SOLVER_OPTIONS),
    #     )
    #     raise RuntimeError(
    #         "An error occuried during validation. See the log for more information"
    #     )
    # if (
    #     self.simulation_data["solver"]["preconditioner"]
    #     not in self.PRECONDITIONER_OPTIONS
    # ):
    #     logger.error(
    #         "The simulator do not have the solver %s available.\nThe list of available solvers is: %s",
    #         self.simulation_data["solver"]["preconditioner"],
    #         ", ".join(self.PRECONDITIONER_OPTIONS),
    #     )
    #     raise RuntimeError(
    #         "An error occuried during validation. See the log for more information"
    #     )
    # # check if model in simulation.toml fileis available
    # model_name = self.simulation_data["simulation"]["model"]
    # if model_name not in AVAILABLE_MODELS:
    #     logger.error(
    #         "The model %s is not available.\nThe list of available models is: %s",
    #         model_name,
    #         ", ".join(AVAILABLE_MODELS.keys()),
    #     )
    #     raise RuntimeError(
    #         "An error occuried during validation. See the log for more information"
    #     )
    # model = AVAILABLE_MODELS[self.simulation_data["simulation"]["model"]]
    # # check the output variables if they are valid variables for the model
    # for output_variables in self.simulation_data["output"]["variables"]:
    #     if output_variables not in model.VARIABLES:
    #         logger.error(
    #             "Invalid variable %s for the model %s.\nThe list of variables for this model is: %s",
    #             output_variables,
    #             model_name,
    #             ", ".join(model.VARIABLES),
    #         )
    #         raise RuntimeError(
    #             "An error occuried during validation. See the log for more information"
    #         )
    # # check the same variables used in tolerance section
    # for tolerance_type in ["relative", "absolute"]:
    #     variables = set(
    #         self.simulation_data["simulation"][f"tolerance_{tolerance_type}"].keys()
    #     )
    #     if not variables == set(model.VARIABLES):
    #         logger.error(
    #             "Tolerance %s should have all variables %s",
    #             tolerance_type,
    #             ", ".join(model.VARIABLES),
    #         )
    #         raise RuntimeError(
    #             "An error occuried during validation. See the log for more information"
    #         )
    # logger.info("logical validation of the simulation.toml success!")
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
    # - make sure all nodes have initial values conditions 
    #   (get all groups numbers, check if each variable has iniital condition value)    
end

