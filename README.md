# WaveFE.jl
A simulator using CBS method to solve Navier-Stokes equations.

## How to install
First clone the repo

```
git clone https://github.com/gabrielantao/WaveFE.git && cd WaveFE
```

then execute the [Pixi](https://prefix.dev/) (it must be installed in your system) instalation command

```
pixi install
``` 

and finally install the Julia packages.

```
cd simulator
julia --project=. -e 'using Pkg; Pkg.instantiate()'
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
See the [how to](/docs/how_to.md) section on how to do simple tasks in the simulator.

## Examples
See the [examples](/docs/case_examples) section for examples of configured cases and see [test cases](/simulator/test/cases) for examples of test cases.

![Flow around semicircle](/docs/case_examples/centered_semicircle/reference/u_1_t1500.png)

## How to contribute
See the [contribute section](/docs/CONTRIBUTING.md) section