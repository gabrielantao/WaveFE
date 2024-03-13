"""A generic equation"""
abstract type Equation end

"""A generic single element"""
abstract type ModelParameters end 

"""A generic Wave method (e.g. explicit implicit)"""
abstract type SimulationMethod end

"""A generic Wave model"""
abstract type SimulationModel end


export Equation, ModelParameters, SimulationMethod, SimulationModel