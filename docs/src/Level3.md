# Status

Status is a struct oriented to save the current status of a given solution. That is, information related to the solution which is more efficient to save in memory than recomputing it all the time. E.g, if the solution is feasible or not.

The default struct provided can save info about:
+ Feasibility (boolean).
+ Optimality (boolean)
+ Value of the objective function (Float64).
+ Left-hand side values (a.k.a, constraint consumption). This is an array of Float64 of the same size that the number of constraints in the problem. Its purpose is to save the left-hand side values produced by a given solution. 

Note that the latter is mainly oriented to save time in the following way: Given a solution and the corresponding left-hand side values in the associated status, when the solution changes, it is possible to update the left-hand side values without recomputing everything from scratch.

To create a default status, just the number of constraints has to be provided.

```julia
numberConstraints = 12;
myStatus = OREnvironment.constructStatus(numberConstraints)
```


## Methods for status

!!! note

    Unless your intention is to extend the default status provided in the package, forget about this section. The same methods are available for the solution struct. Check them in [Solutions](@ref).


```@index
Pages = ["Level3.md"]
```

```@docs
OREnvironment.constructStatus(numberConstraints::Int)
```
```@docs
OREnvironment.is_feasible(s::ORInterface.Status)
```
```@docs
OREnvironment.set_feasible!(s::ORInterface.Status, value::Bool)
```
```@docs
OREnvironment.is_optimal(s::ORInterface.Status)
```
```@docs
OREnvironment.set_optimal!(s::ORInterface.Status, value::Bool)
```
```@docs
OREnvironment.get_objfunction(s::ORInterface.Status)
```
```@docs
OREnvironment.set_objfunction!(s::ORInterface.Status, value::Float64)
```
```@docs
OREnvironment.get_constraint_consumption(s::ORInterface.Status, idxConstraint::Int)
```
```@docs
OREnvironment.set_constraint_consumption!(s::ORInterface.Status, idxConstraint::Int, value::Float64)
```
```@docs
OREnvironment.worst_value(objsense::Symbol)
```
```@docs
OREnvironment.is_first_status_better(s1::ORInterface.Status, s2::ORInterface.Status, objSense::Symbol, feasibilityRequiered::Bool)
```
### Methods for DefaultStatus
If you implement a new status, you also have to implement this method.

```@docs
OREnvironment.update_status!(oldStatus::OREnvironment.DefaultStatus, newStatus::OREnvironment.DefaultStatus)
```
