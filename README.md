# WaveFE.jl
A simulator using Characteristic-Based Split (CBS) method to solve Navier-Stokes equations. The CBS method is a powerful technique for solving fluid dynamics problems, particularly well-suited for those involving incompressible flow. It leverages the concept of characteristics, which are directions along which information propagates in the flow. CBS do this by spliting the governing equations (typically Navier-Stokes equations) into smaller, more manageable sub-problems to solve the equation in steps. 

According Zienkiewicz, Taylor, Nithiarasu (The Finite Element Method for Fluid Dynamics, 7th ed. pag 89):
> We believe that the algorithm introduced in this chapter is currently the most general one available for fluids, as it can be directly applied to almost all physical situations.

So you can expect this as being a robust method to solve this class of problems. It's useful to solve a big set of problems such as:
- Steady or unsteady flow behavior
- Laminar or turbulent flow regimes
- Moving boundaries


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