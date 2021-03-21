# Constraints

By default, the package provides a struct to handle constraints. For each constraint, the following information is saved:

+ The value of the right-hand side.
+ The type of the constraint (<=, = or >=). 
+ The variables (indexes) and coefficients making the left-hand side of the constraint.


With respect to the type of constraint, this is specified as a symbol. Specifically, the valid values are `:lessOrEq`, `:equal` or `:greaterOrEq`.

So for instance, if our MILP problem had the following constraint:

```math
x_1 + 2x_3 - 4x_7 + 3x_9 \leq 17 
```

We would build it as follows:

```julia
vars1   = [1, 3, 7, 9];
coeffs1 = [1.0, 2.0, -4.0, 3.0]; 
rhs1 = 17.0; 
myConstraint1 = OREnvironment.constructConstraint(rhs1, :lessOrEq, vars1, coeffs1);
```

!!! note

    The coefficients and right-hand side values of the constraints must be specified as Float64 numbers. I used to have that as a template so other types (e.g, Int) could be considered. However, I changed my mind and mimic the behavior of [Gurobi](https://www.gurobi.com/), which apparently (maybe I missed something) only works with Float64 numbers. 

As a final example, imagine that in your problem you also had the constraint 

```math
5.3x_3 - 4x_4 \geq 5 
```

Then, you would have to build it as follows:
```julia
vars2   = [3, 4];
coeffs2 = [5.3, -4.0]; 
rhs2 = 5.0; 
myConstraint2 = OREnvironment.constructConstraint(rhs2, :greaterOrEq, vars2, coeffs2);
```

If for any reason this default constraint structure doesn't fulfill your needs, you can always define a new type of constraint while reusing most of the methods available for the default version. See further discussion later on this page.


## Building constraints as in practice

In most cases, you don't build constraints one by one as shown above, but you read them from a file or some data structure. Let's see how this can accomplish in OREnvironment. We show two different ways. One will be more useful than the other depending on the situation.

#### Option 1

Imagine that we have the information about the constraints (variables, coefficients, etc) stored in a dataframe of N rows. Then we will create the constraints as follows:

```julia
constraints = Array{OREnvironment.Constraint, 1}(); # vector of constraints
for i in 1:N
  c = OREnvironment.constructConstraint(df.rhs[i], df.symbol[i], df.vars[i], df.coefs[i]);
  push!(constraints, c);
end
```

#### Option 2

On some occasions, you will have your constraints stored in a text file. Then, you can load the constraints as follows:
```julia
file = "NameOfTheFileWithTheConstraints.txt"
constraints = OREnvironment.read_constraints(file);
```

For an example (which I highly recommed you to read), check the file *./test/sampleConstraints.txt* and the `@testset "read_constraints"` in file  *./test/Constraints.jl*

!!! note

    Function `OREnvironment.read_constraints()` makes some important assumptions in the file to read:
	
    1) In the file, the constraints are separated by a newline. That is, no comma or other character appears at the end of each line.
    1) In the file, all the variables are named as "x". To distinguish between variables an index is added. So for instance, if your constraint were ``2x + 3y + 5 z >= 12``, you should write in your file: 2x1 + 3x2 + 5x3 >= 12.
    1) All the variables must have a coefficient multiplying them. That is, if your constraint is of type ``x_1 + x_2 \leq 3`` you must write 1 as a coefficient. So your constraint in the file looks like: 1x1 + 1x2 <= 3. 
    1) All the terms in the left-hand side are adding. Negative symbols are for the numbers. So for instance, if your constraint were ``4x_3 -5.3x_{12} + x_{152} = 3``, in your file you should write: 4x3 + -5.3x12 + 1x152 = 3.

## Some technical details

The type of constraint considered by default is called `OREnvironment.DefaultConstraint`, which inherits from `OREnvironment.Constraint`. So you can define your own type of constraint and reuse most of the code (if not all) available for `OREnvironment.Constraint` by using inheritance.

An interesting feature of `OREnvironment.DefaultConstraint` is that, although it just asks for the variables and coefficients making the left-hand side of a constraint, it handles this information in a special way. It saves the information distinguishing between variables with a positive coefficient and variables with a negative one. This is an idea that I read from a paper by the people of [LocalSolver](https://www.localsolver.com/), which is particularly useful to develop black-box solver methods. The relationship between variables and coefficients is saved in a Julia dictionary for fast access.

For more information you can always check the source code */src/Constraints.jl*.


## Methods for constraints

We finish this part of the documentation showing the methods available to deal with constraints.

```@index
Pages = ["Level1.md"]
```

```@docs
OREnvironment.constructConstraint(rhs::Float64, constraintType::Symbol, variables::Array{Int,1}, coefficients::Array{Float64,1})
```
```@docs
OREnvironment.get_rhs(c::OREnvironment.Constraint)
```
```@docs
OREnvironment.set_rhs!(c::OREnvironment.Constraint, val::Float64)
```
```@docs
OREnvironment.get_type(c::OREnvironment.Constraint)
```
```@docs
OREnvironment.set_type!(c::OREnvironment.Constraint, val::Symbol)
```
```@docs
OREnvironment.is_variable(c::OREnvironment.Constraint, pos::Int)
```
```@docs
OREnvironment.get_coefficient(c::OREnvironment.Constraint, pos::Int)
```
```@docs
OREnvironment.set_coefficient!(c::OREnvironment.Constraint, pos::Int,
val::Float64)
```
```@docs
OREnvironment.get_relationship_variables_constraints(constraints::Array{<:OREnvironment.Constraint,1}, nVariables::Int)
```
```@docs
OREnvironment.read_constraints(file::String)
```
```@docs
OREnvironment.is_feasible(c::OREnvironment.Constraint, lhs::Float64)
```
```@docs
OREnvironment.is_active(c::OREnvironment.Constraint, lhs::Float64)
```
```@docs
OREnvironment.compute_lhs_after_increment(variable::Int, variable::Real, currentLHS::Float64, c::OREnvironment.Constraint)
```
```@docs
OREnvironment.is_increment_feasible(variable::Int, variable::Real, currentLHS::Float64, c::OREnvironment.Constraint)
```

### Methods where type Solution is also involved
In these methods, an struct called solution is also involved. Check [Solutions](@ref) for a better understanding.
```@docs
OREnvironment.is_increment_feasible(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1}, variable::Int, variable::Real, idxConstraints::Array{Int,1})
```
```@docs
OREnvironment.is_current_consumption_feasible(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1})
```
```@docs
OREnvironment.compute_lhs(c::OREnvironment.Constraint, s::OREnvironment.Solution)
```
```@docs
OREnvironment.is_feasible(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1})
```
```@docs
OREnvironment.is_active(c::OREnvironment.Constraint, s::OREnvironment.Solution)
```
```@docs
OREnvironment.is_active_under_current_consumption(c::OREnvironment.Constraint, idxConstraint::Int, s::OREnvironment.Solution)
```
