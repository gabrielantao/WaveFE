"""A generic equation"""
abstract type Equation end

"""A generic single element"""
abstract type ModelParameters end 

"""Generic Wave model"""
abstract type WaveModel end

export Equation, ModelParameters, WaveModel