# WaveFE.jl

## How to install
First clone the repo 
```
git clone https://github.com/gabrielantao/WaveFE.git && cd WaveFE
```
then execute the Pixi (it must be installed in your system) instalation command
```
pixi install
``` 
and finally install the Julia packages.
```
julia --project=. -e 'using Pkg; Pkg.instantiate()
```
Maybe you can get some warnings about `Warning: CHOLMOD version incompatibility` but you can ignore it for now. This is gonna be fixed in the future.

## Run the tests 
Before start you should run the unit tests to check if everything is working
```
pixi run test-unit -a
```
and you can run the validation cases to make sure the validation tests are ok
```
pixi run test-case -a
```
but this can take a while.


## Usage

## How to contribute