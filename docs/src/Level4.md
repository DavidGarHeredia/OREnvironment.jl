# Solutions

To handle solutions, the package again provides a default struct. This saves the following information:
+ A given status that we want to associate with the solution. See for example the default one implemented in [Status](@ref).
+ A solution representation. The one implemented in the package consists of an array of fixed length (i.e, it does not vary its size once created).

As an example, consider we have a problem with 12 constraints, a total of 9 variables and all of them are integer. Then:

```julia
# We first build the status for the solution
numberConstraints = 12;
myStatus = OREnvironment.constructStatus(numberConstraints);
# Then, we build the rest of the arguments required
typeOfVariables = Int;
numberOfVariables = 9; 
args = (typeOfVariables, numberOfVariables, myStatus);
# Finally, we build the solution 
mySolution = OREnvironment.constructSolution(:FixedLengthArray, args)
```

A couple of important notes:
+ If at least one of the variables is continuous, then use `Float64` instead of `Int`.
+ For each solution you create, build a new status. Naturally, when dealing with multiple solutions you may want all of them to have the same type of status. However, if you simply pass as argument `myStatus` to all the solutions you build, Julia (probably) will create pointers. So instead of having one status per solution, you will have one status for ALL the solutions (which you don't want).

Example of what NOT to do:
```julia
numberConstraints = 12;
myStatus = OREnvironment.constructStatus(numberConstraints);
typeOfVariables = Int;
numberOfVariables = 9; 
args = (typeOfVariables, numberOfVariables, myStatus);

s1 = OREnvironment.constructSolution(:FixedLengthArray, args)
s2 = OREnvironment.constructSolution(:FixedLengthArray, args) # we are recycling the status
```

Example of what to do:
```julia
numberConstraints = 12;
myStatus1 = OREnvironment.constructStatus(numberConstraints);
typeOfVariables = Int;
numberOfVariables = 9; 
args = (typeOfVariables, numberOfVariables, myStatus1);

s1 = OREnvironment.constructSolution(:FixedLengthArray, args)

# See how this time we're building a new status for the new solution
myStatus2 = OREnvironment.constructStatus(numberConstraints);
args = (typeOfVariables, numberOfVariables, myStatus2);
s2 = OREnvironment.constructSolution(:FixedLengthArray, args)
```

## About the constructor

You may wonder why in the constructor (see examples above) you have to provide `:FixedLengthArray` as an argument if, by default, it is the only option available. 

The reason is that, when extending the package to consider other types of representations, you can build those by simply changing the arguments, not the name of the constructor.

As an example, consider that you extend the package to deal with variable length arrays. If the arguments (`args`) to build that solution struct are the same, the only thing of your code that should change is `:FixedLengthArray` by `:VariableLengthArray` (in case you use that identifier).

## Methods for solution

```@index
Pages = ["Level4.md"]
```

```@docs
OREnvironment.constructSolution(solutionType::Symbol, args)
```
```@docs
OREnvironment.is_feasible(s::OREnvironment.Solution)
```
```@docs
OREnvironment.set_feasible!(s::OREnvironment.Solution, value::Bool)
```
```@docs
OREnvironment.is_optimal(s::OREnvironment.Solution)
```
```@docs
OREnvironment.set_optimal!(s::OREnvironment.Solution, value::Bool)
```
```@docs
OREnvironment.get_objfunction(s::OREnvironment.Solution)
```
```@docs
OREnvironment.set_objfunction!(s::OREnvironment.Solution, value::Float64)
```
```@docs
OREnvironment.get_constraint_consumption(s::OREnvironment.Solution, idxConstraint::Int)
```
```@docs
OREnvironment.set_constraint_consumption!(s::OREnvironment.Solution, idxConstraint::Int, value::Float64)
```
```@docs
OREnvironment.is_first_solution_better(s1::OREnvironment.Solution,s2::OREnvironment.Solution, objSense::Symbol,feasibilityRequired::Bool)
```

### Methods for Solution when dealing with Constraints

```@docs
OREnvironment.update_constraint_consumption!(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1})
```
```@docs
OREnvironment.update_constraint_consumption_and_feasibility!(s::OREnvironment.Solution,  constraints::Array{<:OREnvironment.Constraint,1})
```
```@docs
OREnvironment.update_constraint_consumption!(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1}, variable::Int, Δvariable::Real, idxConstraints::Array{Int,1})
```
```@docs
OREnvironment.update_constraint_consumption_and_feasibility!(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1}, variable::Int, Δvariable::Real, idxConstraints::Array{Int,1})
```


### Methods for FixLenghtArray

These have to be reimplemented when extending the package to new solution structures.


```@docs
OREnvironment.get_solution(s::OREnvironment.FixedLengthArray{T}, variable::Int) where {T<:Real}
```
```@docs
OREnvironment.add_solution!(s::OREnvironment.FixedLengthArray{T}, variable::Int, value::T) where {T<:Real}
```
```@docs
OREnvironment.remove_solution!(s::OREnvironment.FixedLengthArray{T}, variable::Int) where {T<:Real}
```
```@docs
OREnvironment.remove_all_solutions!(s::OREnvironment.FixedLengthArray{T}) where {T<:Real}
```
```@docs
OREnvironment.add_solution_and_update_status!(s::OREnvironment.FixedLengthArray{T}, variable::Int, value::T, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.remove_solution_and_update_status!(s::OREnvironment.FixedLengthArray{T}, variable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.remove_all_solutions_and_update_status!(s::OREnvironment.FixedLengthArray{T}, p::OREnvironment.Problem) where {T<:Real}
```
