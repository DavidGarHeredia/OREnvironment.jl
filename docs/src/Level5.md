
# Movements

When developing algorithms, some operations repeatedly appear to explore the solution space. Here we provide functions for some of those so they do not have to be programmed by the user.

## Methods for solution

```@index
Pages = ["Level5.md"]
```

```@docs
OREnvironment.inverse_order!(s::OREnvironment.FixedLengthArray{T}, firstVariable::Int, lastVariable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.undo_inverse!(s::OREnvironment.FixedLengthArray{T}, firstVariable::Int, lastVariable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.swap_values!(s::OREnvironment.FixedLengthArray{T}, variable1::Int, variable2::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.undo_swap!(s::OREnvironment.FixedLengthArray{T}, variable1::Int, variable2::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.flip_value!(s::OREnvironment.FixedLengthArray{T}, variable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.undo_flip!(s::OREnvironment.FixedLengthArray{T}, variable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.mirror_value!(s::OREnvironment.FixedLengthArray{T}, variable::Int, p::OREnvironment.Problem) where {T<:Real}
```
```@docs
OREnvironment.undo_mirror!(s::OREnvironment.FixedLengthArray{T}, variable::Int, p::OREnvironment.Problem) where {T<:Real}
```