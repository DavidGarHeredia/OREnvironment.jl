############################
# Types & Constructors
############################
mutable struct FixedLengthArray{T<:Real} <: Solution
    sol::Array{T,1};
    status::Status;
end

"""
    constructSolution(solutionType, args)

Constructs a container of type `solutionType` for the solution. Note that the arguments of the constructor are provided in `args`.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
```
"""
function constructSolution(solutionType::Symbol, args)
    return constructSolution(Val(solutionType), args...);
end

function constructSolution(::Val{:FixedLengthArray}, 
                           typeVariables::DataType, 
                           numVariables::Int, 
                           status::Status)
    return FixedLengthArray(zeros(typeVariables, numVariables), status);
end


############################
# General methods for Solution
############################
"""
    is_feasible(s)

Returns the feasibility value of solution `s`.
# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.is_feasible(s)
false
```
"""
is_feasible(s::Solution)::Bool = is_feasible(s.status);

"""
    set_feasible!(s, val)

Sets the feasibility value of solution `s` to `val`.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_feasible!(s, true)
julia> OREnvironment.is_feasible(s)
true
```
"""
set_feasible!(s::Solution, value::Bool) = set_feasible!(s.status, value);

"""
    is_optimal(s)

Returns the optimality value of solution `s`.
# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.is_optimal(s)
false
```
"""
is_optimal(s::Solution)::Bool = is_optimal(s.status); 

"""
    set_optimal!(s, val)

Sets the optimality value of solution `s` to `val`.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_optimal!(s, true)
julia> OREnvironment.is_optimal(s)
true
```
"""
set_optimal!(s::Solution, value::Bool) = set_optimal!(s.status, value); 

"""
    get_objfunction(s)

Returns the objective function value of solution `s`.
# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.get_objfunction(s)
0.0
```
"""
get_objfunction(s::Solution)::Float64 = get_objfunction(s.status);

"""
    set_objfunction!(s, val)

Sets the objective function value of solution `s` to `val`.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_objfunction!(s, 15.66)
julia> OREnvironment.get_objfunction(s)
15.66
```
"""
set_objfunction!(s::Solution, value::Float64) = set_objfunction!(s.status, value);

"""
    get_constraint_consumption(s, idx)

Returns the consumption of the `idx` constraint in solution `s`. 

**Note:** It returns the stored value, This method does not compute the consumption based on the current solution.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.get_constraint_consumption(s, 2)
0.0
```
"""
@inline function get_constraint_consumption(s::Solution, idxConstraint::Int)::Float64 
    return get_constraint_consumption(s.status, idxConstraint); 
end

"""
    set_constraint_consumption!(s, idx, val)

Sets the consumption of the `idx` constraint in solution `s` to value `val`. 

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_constraint_consumption(s, 2, 3.4);
julia> OREnvironment.get_constraint_consumption(s, 2)
3.4
```
"""
@inline function set_constraint_consumption!(s::Solution, idxConstraint::Int, value::Float64) 
    set_constraint_consumption!(s.status, idxConstraint, value); 
end

"""
    is_first_solution_better(s1, s2, objSense, feasibilityRequired)

Returns if solution `s1` is better than solution `s2`. For the comparaison is required the objective function sense and if feasibility is a must in the comparaison.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s1 = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_feasible!(s1, true);
julia> OREnvironment.set_objfunction!(s1, 19.8);
julia> s2 = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.set_feasible!(s2, false);
julia> OREnvironment.set_objfunction!(s2, 100.0);
julia> OREnvironment.is_first_solution_better(s1, s2, :max, true)
julia> true
julia> OREnvironment.is_first_solution_better(s1, s2, :max, false)
julia> false
julia> OREnvironment.set_feasible!(s2, true);
julia> OREnvironment.is_first_solution_better(s1, s2, :max, true)
julia> false
julia> OREnvironment.is_first_solution_better(s1, s2, :min, true)
julia> true
``` 
"""
function is_first_solution_better(s1::Solution, 
                                  s2::Solution, 
                                  objSense::Symbol, 
                                  feasibilityRequired::Bool)::Bool
    return is_first_status_better(s1.status, s2.status, objSense, feasibilityRequired);
end

############################
# Specific methods for Solution
############################

"""
    get_solution(s, var)

Returns the solution value of variable/index `var`.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.get_solution(s, 2)
0
```
"""
@inline function get_solution(s::FixedLengthArray{T}, variable::Int) where {T<:Real} 
    return @inbounds s.sol[variable];
end

"""
    add_solution!(s, var, val)

Sets the solution value of variable/index `var` to `val`

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.add_solution!(s, 2, 4)
julia> OREnvironment.get_solution(s, 2)
4
```
"""
@inline function add_solution!(s::FixedLengthArray{T}, variable::Int, value::T) where {T<:Real} 
    @inbounds s.sol[variable] = value;
end

"""
    remove_solution!(s, var)

Sets the solution value of variable/index `var` to 0.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.add_solution!(s, 2, 4)
julia> OREnvironment.get_solution(s, 2)
4
julia> OREnvironment.remove_solution!(s, 2)
julia> OREnvironment.get_solution(s, 2)
0
```
"""
@inline function remove_solution!(s::FixedLengthArray{T}, variable::Int) where {T<:Real} 
    @inbounds s.sol[variable] = zero(T);
end

"""
    remove_all_solution!(s)

Sets the solution value of all the variables to 0.

# Example
```jldoctest
julia> typeOfVariables = Int; numVariables = 5;  numConstraints = 3;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> OREnvironment.add_solution!(s, 1, 12)
julia> OREnvironment.get_solution(s, 1)
12
julia> OREnvironment.add_solution!(s, 2, 4)
julia> OREnvironment.get_solution(s, 2)
4
julia> OREnvironment.remove_all_solution!(s)
julia> OREnvironment.get_solution(s, 1)
0
julia> OREnvironment.get_solution(s, 2)
0
```
"""
function remove_all_solutions!(s::FixedLengthArray{T}) where {T<:Real}
    s.sol .= zero(T);
    return nothing;
end

"""
    copy_first_solution_to_second(s1, s2)

Copies all the information of the first solution (`s1`) into the second one (`s2`).

See file *./test/Solution.jl* for an example.
"""
@inline function copy_first_solution_to_second!(s1::FixedLengthArray{T}, 
                                                s2::FixedLengthArray{T}) where {T<:Real}
    update_status!(s2.status, s1.status); 
    copy!(s2.sol, s1.sol);
    return nothing;
end

############################
# General methods for Solution when dealing with constraints
############################
"""
    update_constraint_consumption!(s, vconstr)

Given solution `s` and the constraints of the problem `vconstr`, this method computes the left-hand side of the constraints (constraint consumption) and saves the values in memory.

See file *./test/Solution.jl* for an example.
"""
function update_constraint_consumption!(s::Solution, 
                                        constraints::Array{<:Constraint,1})
    local N::Int = length(constraints);
    @inbounds for i in 1:N 
        local lhs::Float64 = compute_lhs(constraints[i], s);
        set_constraint_consumption!(s, i, lhs);
    end
    return nothing;
end

"""
    update_constraint_consumption_and_feasibility!(s, vconstr)

Given solution `s` and the constraints of the problem `vconstr`, this method computes the left-hand side of the constraints (constraint consumption), saves the values in memory and update the feasibility status according to the results obtained.

See file *./test/Solution.jl* for an example.
"""
function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1})
    local feasible::Bool = true;
    local N::Int = length(constraints);
    @inbounds for i in 1:N 
        local lhs::Float64 = compute_lhs(constraints[i], s);
        set_constraint_consumption!(s, i, lhs);
        local isfeasible::Bool = is_feasible(constraints[i], lhs);
        if !isfeasible feasible = false; end
    end
    set_feasible!(s, feasible);
    return nothing;
end

"""
    update_constraint_consumption!(s, vconstr, var, Δ, idxConstraints)

Updates constraint consuption of solution `s` for the constraints of the problem (`vconstr`) when variable `var` has changed its value by `Δ`. `idxConstraints` is the vector of constraint indexes where variable `var` appears.

Note that this method is more efficient than updating the constraint consumption by recomputing again all the left-hand sides of the constraints: Most of the constraints does not change when modifying a variable, and those which change, only do it in one variable! Thus, if only a few changes have occurred in the vector of solutions since the last update, this incremental method should be preferred.

See file *./test/Solution.jl* for an example.
"""
function update_constraint_consumption!(s::Solution, 
                                        constraints::Array{<:Constraint,1}, 
                                        variable::Int, 
                                        Δvariable::Real, 
                                        idxConstraints::Array{Int,1})
    @inbounds for i in idxConstraints
        local currentLHS::Float64 = get_constraint_consumption(s, i);
        local lhs::Float64 = compute_lhs_after_increment(variable, Δvariable, 
                                                     currentLHS, constraints[i]);
        set_constraint_consumption!(s, i, lhs);
    end
    return nothing;
end

"""
    update_constraint_consumption_and_feasibility!(s, vconstr, var, Δ, idxConstraints)

Updates constraint consuption of solution `s`, and its feasibility status, for the constraints of the problem (`vconstr`) when variable `var` has changed its value by `Δ`. `idxConstraints` is the vector of constraint indexes where variable `var` appears.

Note that this method is more efficient than updating the constraint consumption by recomputing again all the left-hand sides of the constraints: Most of the constraints does not change when modifying a variable, and those which change, only do it in one variable! Thus, if only a few changes have occurred in the vector of solutions since the last update, this incremental method should be preferred.

See file *./test/Solution.jl* for an example.
"""
function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1}, 
                                                        variable::Int, 
                                                        Δvariable::Real, 
                                                        idxConstraints::Array{Int,1})
    local feasible::Bool = true;
    @inbounds for i in idxConstraints
        local currentLHS::Float64 = get_constraint_consumption(s, i);
        local lhs::Float64 = compute_lhs_after_increment(variable, Δvariable, 
                                                    currentLHS, constraints[i]);
        set_constraint_consumption!(s, i, lhs);
        local isfeasible::Bool = is_feasible(constraints[i], lhs);
        if !isfeasible feasible = false; end
    end

    if should_global_feasibility_be_checked(is_feasible(s), feasible)
        feasible = is_current_consumption_feasible(s, constraints);
    end
    set_feasible!(s, feasible); 
    return nothing;
end

function should_global_feasibility_be_checked(isSolutionFeasible::Bool, 
                                              isIncrementFeasible::Bool)::Bool
    # if the solution was not already feasible but the current movement is,
    # then feasibility must be set checking all the constraints.
    return !isSolutionFeasible && isIncrementFeasible;
end

############################
# Specific methods for Solution
############################
"""
    add_solution_and_update_status!(s, var, val, p)
    
Sets the solution value of variable/index `var` to `val` and updates the status of the solution (including the consumption of the constraints in problem `p`).

See file *./test/Solution.jl* for an example.
"""
function add_solution_and_update_status!(s::FixedLengthArray{T}, 
                                         variable::Int, 
                                         value::T, 
                                         p::Problem) where {T<:Real}
    @inbounds local Δ::T  = value - s.sol[variable];
    local newObj::Float64 = get_objfunction(s) + Δ*get_cost(p, variable);
    @inbounds s.sol[variable] = value;
    update_constraint_consumption_and_feasibility!(s, get_constraints(p), 
                            variable, Δ, get_constraints_of_variable(p, variable));
    set_objfunction!(s, newObj);
    return nothing;
end

"""
    remove_solution_and_update_status!(s, var, p)
    
Sets the solution value of variable/index `var` to 0 and updates the status of the solution (including the consumption of the constraints in problem `p`).

See file *./test/Solution.jl* for an example.
"""
function remove_solution_and_update_status!(s::FixedLengthArray{T}, 
                                            variable::Int, 
                                            p::Problem) where {T<:Real}
    add_solution_and_update_status!(s, variable, zero(T), p);
    return nothing;
end

"""
    remove_all_solution_and_update_status!(s, p)
    
Sets the solution value of all the variables to 0 and updates the status of the solution (including the consumption of the constraints in problem `p`).

See file *./test/Solution.jl* for an example.
"""
function remove_all_solutions_and_update_status!(s::FixedLengthArray{T},
                                                 p::Problem) where {T<:Real}
    s.sol .= zero(T);
    set_objfunction!(s, 0.0);
    s.status.constraintLhsConsumption .= 0.0;
    local feasible::Bool = is_current_consumption_feasible(s, get_constraints(p));
    set_feasible!(s, feasible);
    return nothing;
end
