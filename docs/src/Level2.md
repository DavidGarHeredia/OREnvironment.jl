# Problem environment

Usually, in MILP, a problem is defined by an objective function and a collection of constraints. To handle this structure altogether, OREnvironment provides a struct which saves the following information:

+ The cost coefficients of the objective function. This is an array of Float64.
+ An array with the constraints of the problem. See [Constraints](@ref).
+ An array where the i-th element is an array with the constraint indexes where the i-th variable appears. This array is used for efficiency reasons in operations and it is built automatically by the constructor calling method [`OREnvironment.get_relationship_variables_constraints`](@ref).
+ The sense of the optimization problem. Valid symbols are `:max` and `:min`.
+ The bounds of the variables.

As an example of how to build a problem, let's assume we have a vector of costs and a vector with the constraints of the problem. See [Constraints](@ref) for examples and details about how to build the latter. Then:

```julia
cost = rand(6); # so we have 6 variables in the problem
c1 = OREnvironment.constructConstraint(15.0, :lessOrEq, [1,3,4,6], [2.3, 3.2, 3.1, 12.34]);
c2 = OREnvironment.constructConstraint(9.0,  :lessOrEq, [1,3,5,6], [3.3, 4.2, 4.1, 13.34]);
constraints = [c1, c2];
domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
myProblem = OREnvironment.constructProblem(cost, constraints, :max, domain) 
```

## Methods for problem

```@index
Pages = ["Level2.md"]
```

```@docs
OREnvironment.constructProblem(costs::Array{Float64,1},constraints::Array{<:ORInterface.Constraint,1},objSense::Symbol,domain::Array{OREnvironment.VariableDomain,1}) 
```

```@docs
OREnvironment.get_lb_variable(p::ORInterface.Problem, variable::Int)
```

```@docs
OREnvironment.set_lb_variable!(p::ORInterface.Problem, variable::Int, lb::Float64) 
```

```@docs
OREnvironment.get_ub_variable(p::ORInterface.Problem, variable::Int) 
```

```@docs
OREnvironment.set_ub_variable!(p::ORInterface.Problem, variable::Int, ub::Float64) 
```

```@docs
OREnvironment.is_value_within_the_domain(p::ORInterface.Problem, variable::Int, value::T) where {T<:Real}
```

```@docs
OREnvironment.get_middle_point_variable_domain(p::ORInterface.Problem, variable::Int)
```

```@docs
OREnvironment.get_number_of_variables(p::ORInterface.Problem) 
```

```@docs
OREnvironment.get_number_of_constraints(p::ORInterface.Problem) 
```

```@docs
OREnvironment.get_cost(p::ORInterface.Problem, variable::Int) 
```

```@docs
OREnvironment.set_cost!(p::ORInterface.Problem, variable::Int, value::Float64)
```
```@docs
OREnvironment.get_obj_sense(p::ORInterface.Problem)
```
```@docs
OREnvironment.set_obj_sense!(p::ORInterface.Problem, value::Symbol)
```
```@docs
OREnvironment.get_constraint(p::ORInterface.Problem, idxConstraint::Int)
```
```@docs
OREnvironment.get_constraints(p::ORInterface.Problem)
```
```@docs
OREnvironment.get_constraints_of_variable(p::ORInterface.Problem, variable::Int)
```
```@docs
OREnvironment.add_constraint!(p::ORInterface.Problem, c::ORInterface.Constraint) 
```
```@docs
OREnvironment.is_feasible(p::ORInterface.Problem, s::ORInterface.Solution)
```
```@docs
OREnvironment.gap(lowerBound::Float64, upperBound::Float64, objSense::Symbol)
```
