############################
# Types & Constructors
############################
Base.@kwdef mutable struct DefaultStatus <: Status
    feasible::Bool = false;
    optimal::Bool  = false; 
    objfunction::Float64 = 0.0;
    constraintLhsConsumption::Array{Float64,1};
end

"""
    constructStatus(nConstraints)

Constructs a `DefaultStatus`. It is necessary to specify the number of constraints of the problem.

# Example
```jldoctest
julia> OREnvironment.constructStatus(5);
``` 
"""
function constructStatus(numberConstraints::Int)
    return DefaultStatus(constraintLhsConsumption = zeros(Float64, numberConstraints));
end

############################
# General methods for Status
############################
"""
    is_feasible(s)

Returns the feasibility value of status `s`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.is_feasible(s)
false
``` 
"""
is_feasible(s::Status)::Bool = s.feasible;

"""
    set_feasible!(s, val)

Sets the feasibility value of status `s` to `val`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.set_feasible!(s, true);
julia> OREnvironment.is_feasible(s)
true
``` 
"""
set_feasible!(s::Status, value::Bool) = s.feasible = value;

"""
    is_optimal(s)

Returns the optimality value of status `s`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.is_optimal(s)
false
``` 
"""
is_optimal(s::Status)::Bool = s.optimal; 

"""
    set_optimal!(s, val)

Sets the optimality value of status `s` to `val`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.set_optimal!(s, true);
julia> OREnvironment.is_optimal(s)
true
``` 
"""
set_optimal!(s::Status, value::Bool) = s.optimal = value; 

"""
    get_objfunction(s)

Returns the objective function value of status `s`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.get_objfunction(s)
0.0
``` 
"""
get_objfunction(s::Status)::Float64 = s.objfunction;

"""
    set_objfunction!(s, val)

Sets the objective function value of status `s` to `val`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.set_objfunction!(s, 19.8);
julia> OREnvironment.get_objfunction(s)
19.8
``` 
"""
set_objfunction!(s::Status, value::Float64) = s.objfunction = value;

"""
    get_constraint_consumption(s, idx)

Returns the consumption of the `idx`-th constraint in status `s`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.get_constraint_consumption(s, 1)
0.0
``` 
"""
get_constraint_consumption(s::Status, idxConstraint::Int)::Float64 = @inbounds s.constraintLhsConsumption[idxConstraint];

"""
    set_constraint_consumption!(s, idx, val)

Sets the consumption of the `idx`-th constraint to `val` in status `s`.

# Example
```jldoctest
julia> s = OREnvironment.constructStatus(5);
julia> OREnvironment.set_constraint_consumption!(s, 2, 3.4);
julia> OREnvironment.get_constraint_consumption(s, 2)
3.4
``` 
"""
set_constraint_consumption!(s::Status, idxConstraint::Int, value::Float64) = @inbounds s.constraintLhsConsumption[idxConstraint] = value;

"""
    worst_value(objSense)

Returns the worst value of the objetive function according to the objective sense of the problem.

# Example
```jldoctest
julia> OREnvironment.worst_value(:max)
-Inf
julia> OREnvironment.worst_value(:min)
Inf
``` 
"""
worst_value(objsense::Symbol)::Float64 = worst_value(Val(objsense));
worst_value(::Val{:max})::Float64 = typemin(Float64);
worst_value(::Val{:min})::Float64 = typemax(Float64);

"""
    is_first_status_better(s1, s2, objSense, feasibilityRequiered)

Returns if status `s1` is better than status `s2`. For the comparaison is required the objective function sense and if feasibility is a must for the comparaison.

# Example
```jldoctest
julia> s1 = OREnvironment.constructStatus(5);
julia> OREnvironment.set_feasible!(s1, true);
julia> OREnvironment.set_objfunction!(s1, 19.8);
julia> s2 = OREnvironment.constructStatus(5);
julia> OREnvironment.set_feasible!(s2, false);
julia> OREnvironment.set_objfunction!(s2, 100.0);
julia> OREnvironment.is_first_status_better(s1, s2, :max, true)
true
julia> OREnvironment.is_first_status_better(s1, s2, :max, false)
false
julia> OREnvironment.set_feasible!(s2, true);
julia> OREnvironment.is_first_status_better(s1, s2, :max, true)
false
julia> OREnvironment.is_first_status_better(s1, s2, :min, true)
true
``` 
"""
function is_first_status_better(s1::Status, 
                                s2::Status, 
                                objSense::Symbol, 
                                feasibilityRequiered::Bool)::Bool
    if feasibilityRequiered
        if is_feasible(s1) && !is_feasible(s2)
            return true;
        elseif !is_feasible(s1) && is_feasible(s2)
            return false;
        end
    end
    # In any other situation we compare the objective function 
    return is_first_obj_function_better(s1, s2, Val(objSense));
end

is_first_obj_function_better(s1::Status, s2::Status, ::Val{:max})::Bool = get_objfunction(s1) > get_objfunction(s2);
is_first_obj_function_better(s1::Status, s2::Status, ::Val{:min})::Bool = get_objfunction(s1) < get_objfunction(s2);


############################
# Specific methods for Status
############################
"""
    update_status!(s1, s2)

Copies info of status `s2` to `s1`.

# Example
```jldoctest
julia> s1 = OREnvironment.constructStatus(5);
julia> s2 = OREnvironment.constructStatus(5);
julia> OREnvironment.set_feasible!(s2, true);
julia> OREnvironment.set_optimal!(s2, true);
julia> OREnvironment.set_objfunction!(s2, 100.0);
julia> OREnvironment.is_feasible(s1)
false
julia> OREnvironment.is_optimal(s1)
false
julia> OREnvironment.get_objfunction(s1)
0.0
julia> OREnvironment.update_status!(s1, s2);
julia> OREnvironment.is_feasible(s1)
true
julia> OREnvironment.is_optimal(s1)
true
julia> OREnvironment.get_objfunction(s1)
100.0
``` 
"""
function update_status!(oldStatus::DefaultStatus,
                        newStatus::DefaultStatus)
    set_objfunction!(oldStatus, get_objfunction(newStatus));
    set_feasible!(oldStatus, is_feasible(newStatus));
    set_optimal!(oldStatus, is_optimal(newStatus)); 
    copy!(oldStatus.constraintLhsConsumption, newStatus.constraintLhsConsumption);
    return nothing;
end
