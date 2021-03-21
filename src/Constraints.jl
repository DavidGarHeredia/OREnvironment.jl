
mutable struct DefaultConstraint <: Constraint
    rhs::Float64;
    type::Symbol;
    variablesPositiveCoefficients::Dict{Int,Float64}; 
    variablesNegativeCoefficients::Dict{Int,Float64}; 
end

"""
    constructConstraint(rhs, t, vars, coefs)

Constructs a `DefaultConstraint` with right-hand side `rhs`, type `t` and left-hand side given by the variables in `vars` and coefficients in `coefs`.

**Note:** Both, the rhs and coefs must be of type Float64.

# Example
```jldoctest
julia> OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
```
"""
function constructConstraint(rhs::Float64, 
                             constraintType::Symbol, 
                             variables::Array{Int,1}, 
                             coefficients::Array{Float64,1}) 
    dictPositive = Dict{Int,Float64}();
    dictNegative = Dict{Int,Float64}();
    @inbounds for i in 1:length(variables)
        if coefficients[i] > 0.0
            dictPositive[variables[i]] = coefficients[i];
        else
            dictNegative[variables[i]] = coefficients[i];
        end
    end
    return DefaultConstraint(rhs, constraintType, dictPositive, dictNegative);
end

"""
    get_rhs(c)

Returns the right-hand side value of constraint `c`

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.get_rhs(c)
12.0
```
"""
get_rhs(c::Constraint)::Float64 = c.rhs;

"""
    set_rhs!(c, val)

Sets the right-hand side value of constraint `c` to `val`

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.set_rhs!(c, 25.0); 
julia> OREnvironment.get_rhs(c)
25.0
```
"""
set_rhs!(c::Constraint, value::Float64) = c.rhs = value;

"""
    get_type(c)

Returns the constraint type of `c`. Admisible values are :lessOrEq, :equal and :greaterOrEq.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.get_type(c)
:lessOrEq
```
"""
get_type(c::Constraint)::Symbol = c.type;

"""
    set_type!(c, val)

Sets the constraint type of `c` to `val`. Admisible values are :lessOrEq, :equal and :greaterOrEq.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.set_type!(c, :greaterOrEq);
julia> OREnvironment.get_type(c)
:greaterOrEq
```
"""
set_type!(c::Constraint, value::Symbol) = c.type = value;

"""
    is_variable(c, var)

Returns true if variable `var` is in constraint `c`.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.is_variable(c, 33)
true
julia> OREnvironment.is_variable(c, 13)
false
```
"""
function is_variable(c::Constraint, variable::Int)::Bool
    local answer::Bool = haskey(c.variablesPositiveCoefficients, variable) || 
                         haskey(c.variablesNegativeCoefficients, variable);
   return answer; 
end

"""
    get_coefficient(c, var)

Returns the coefficient of variable `var` in constraint `c`. If the variable is not in the constraint it returns 0.0;


# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.get_coefficient(c, 33)
1.0
julia> OREnvironment.get_coefficient(c, 3)
5.0
```
"""
function get_coefficient(c::Constraint, variable::Int)::Float64
    local value::Float64 = get(c.variablesPositiveCoefficients, variable, 0.0);
    if value == 0.0
        value = get(c.variablesNegativeCoefficients, variable, 0.0);
    end
    return value;
end

"""
    set_coefficient!(c, var, coef)

Sets in constraint `c` coefficient `coef` for variable `var`. 

**Note:** If the variable was not in the constraint, it is added to it. Note that the vector that relates variables and constraints in the `Problem` struct is not updated when calling this adding a variable using this method!

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 12, 33], [2.0, 5.0, 3.0, 1.0]);
julia> OREnvironment.set_coefficient!(c, 33, 123.0);
julia> OREnvironment.get_coefficient(c, 33)
123.0
```
"""
function set_coefficient!(c::Constraint, variable::Int, value::Float64)
    if value > 0.0
        c.variablesPositiveCoefficients[variable] = value;
    else
        c.variablesNegativeCoefficients[variable] = value;
    end
    return nothing;
end

"""
    get_relationship_variables_constraints(vconstraints, nVariables)

Given an Array of constraints `vconstraints` and the number of variables in the problem, returns an Array where the i-th element is an Array with the indexes of the constraints where the i-th variable appears.

This function is employed in the `Problem` struct so it is possible to quickly identify what constraints in the problem are affected when a variable changes its value. This permits faster updates of the left-hand side value associated to a given solution.

# Example
```jldoctest
julia> c1 = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 4], [2.0, 5.0, 3.0]);
julia> c2 = OREnvironment.constructConstraint(5.0, :equal, [2, 3, 5], [9.0, 1.0, 7.0]);
julia> constraints = [c1, c2];
julia> nVariables = 5;
julia> OREnvironment.get_relationship_variables_constraints(constraints, nVariables)
5-element Array{Array{Int64,1},1}:
 [1]
 [2]
 [1, 2]
 [1]
 [2]
 # So variable 1 appears in constraint 1, variable 2 in constraint 2, 
 # variable 3 in constraints 1 and 2...
```
"""
function get_relationship_variables_constraints(constraints::Array{<:Constraint,1}, 
                                                nVariables::Int)::Array{Array{Int,1}, 1}
    if length(constraints) == 0 return Array{Array{Int,1}, 1}() end
    variablesConstraints = [Int[] for i in 1:nVariables];
    @inbounds for i in 1:length(constraints)
      add_constraint_index_to_variables!(constraints[i], i, variablesConstraints);
    end
    return variablesConstraints;
end

function add_constraint_index_to_variables!(c::Constraint, 
                                            idx::Int,
                                            variablesConstraints::Array{Array{Int,1}, 1})  
    @inbounds for variable in keys(c.variablesPositiveCoefficients)
        push!(variablesConstraints[variable], idx);
    end
    @inbounds for variable in keys(c.variablesNegativeCoefficients)
        push!(variablesConstraints[variable], idx);
    end
    return nothing;
end

"""
    read_constraints(file)

Returns an Array of constraints. The constraints are read from `file`.

See example in the file with the tests: *./test/Constraints.jl*.
"""
function read_constraints(file::String)
    fileStream = open(file, "r");
    lines = readlines(fileStream);
    constraints = [constructConstraint(0.0, :equal, Int[], Array{Float64,1}()) 
                   for i in 1:length(lines)];
    @inbounds Threads.@threads for i in 1:length(lines)
      parse_constraint!(constraints[i], lines[i], i);
    end
    return constraints;
end

function parse_constraint!(c::Constraint, line::String, idx::Int)
    local sign = parse_and_set_constraint_sign!(c, line, idx);
    elements = split(line, sign);

    set_rhs!(c, parse(Float64, elements[2]));

    lhs = split(elements[1], "+");
    @inbounds for i in 1:length(lhs)
      terms = split(lhs[i], "x");
      coef = parse(Float64, terms[1]);
      var  = parse(Int, terms[2]);
      set_coefficient!(c, var, coef);
    end
end

function parse_and_set_constraint_sign!(c::Constraint, line::String, idx::Int)
    local sign = "";
    if occursin("<=", line)
      sign = "<=";
      set_type!(c, :lessOrEq);
    elseif occursin(">=", line)
      sign = ">=";
      set_type!(c, :greaterOrEq);
    elseif occursin("=", line) && !occursin("<", line) && !occursin(">", line) && !occursin("==", line)
      sign = "=";
      set_type!(c, :equal);
    else
      error("Incorrect sign in constraint ", idx, ". Maybe you wrote => instead of >=, or == instead of =");
    end
    return sign;
end

"""
    is_feasible(c, lhs)

Given a constraint `c`, returns if the left-hand side consumption `lhs` is feasible or not.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 4], [2.0, 5.0, 3.0]);
julia> OREnvironment.is_feasible(c, 6.0)
true
julia> OREnvironment.is_feasible(c, 16.0)
false
```
"""
is_feasible(c::Constraint, lhs::Float64)::Bool = is_feasible(get_rhs(c), lhs, Val(get_type(c))); 
is_feasible(rhs::Float64, lhs::Float64, ::Val{:lessOrEq})::Bool    = lhs <= rhs;
is_feasible(rhs::Float64, lhs::Float64, ::Val{:equal})::Bool       = lhs ≈ rhs;
is_feasible(rhs::Float64, lhs::Float64, ::Val{:greaterOrEq})::Bool = lhs >= rhs;

"""
    is_active(c, lhs)

Given a constraint `c`, returns if the left-hand side consumption `lhs` makes the constraint active or not.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 4], [2.0, 5.0, 3.0]);
julia> OREnvironment.is_active(c, 6.0)
false
julia> OREnvironment.is_active(c, 12.0)
true
```
"""
is_active(c::Constraint, lhs::Float64)::Bool = lhs ≈ get_rhs(c);

"""
    compute_lhs_after_increment(var, Δ, currentLHS, c)

For a change of `Δ` in the value of variable `var`, returns the new left-hand side consumption in constraint `c` given the current consumption `currentLHS`.


# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 4], [2.0, 5.0, 3.0]);
julia> Δ = 3; currentLHS = 9.0;
julia> OREnvironment.compute_lhs_after_increment(1, Δ, currentLHS, c)
15.0 # = 2*Δ + currentLHS
```
"""
function compute_lhs_after_increment(variable::Int, 
                                     Δvariable::Real,
                                     currentLHS::Float64, 
                                     c::Constraint)::Float64
    local Δconsumption::Float64 = Δvariable*get_coefficient(c, variable);
    local lhs::Float64 = currentLHS + Δconsumption; 
    return lhs;
end

"""
    is_increment_feasible(var, Δ, currentLHS, c)

For a change of `Δ` in the value of variable `var`, returns if new left-hand side consumption in constraint `c` is feasible given the current consumption `currentLHS`.
# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12.0, :lessOrEq, [1, 3, 4], [2.0, 5.0, 3.0]);
julia> Δ = 3; currentLHS = 9.0;
julia> OREnvironment.is_increment_feasible(1, Δ, currentLHS, c)
false # new lhs would be 15 which larger than 12
```
"""
function is_increment_feasible(variable::Int, 
                               Δvariable::Real,
                               currentLHS::Float64, 
                               c::Constraint)::Bool
    local lhs::Float64 = compute_lhs_after_increment(variable, Δvariable, currentLHS, c);
    local answer::Bool = is_feasible(c, lhs);
    return answer;
end


############################
# General methods for Constraints when dealing with Solutions
############################
"""
    is_increment_feasible(s, vconstraints, var, Δ, idxConstraints)

Given solution `s`, the constraints of the problem `vconstraints`, a change `Δ` (respect to the current solution `s`) in variable `var` and an Array with the constraint indexes where variable `var` appears, returns if the change is feasible or not.

**Note:** That the change is feasible DOES NOT mean that the solution is feasible. Given a feasible solution, a feasible change implies that the new solution is still feasible. But given an infeasible solution, a feasible change means that the constraints where `var` appears are not violated by the current change. However, as the original solution was infeasible, the new one is still infeasible. If the return of the function is `false`, then the solution after the change is infeasible regardless of the original feasibility situation.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_increment_feasible(s::Solution, 
                               constraints::Array{<:Constraint,1}, 
                               variable::Int, 
                               Δvariable::Real, 
                               idxConstraints::Array{Int,1})::Bool
    @inbounds for i in idxConstraints
        local currentLHS::Float64 = get_constraint_consumption(s, i);
        local feasible::Bool = is_increment_feasible(variable, Δvariable, currentLHS, constraints[i]);
        if !feasible
            return false;
        end
    end
    return true;
end

"""
    is_current_consumption_feasible(s, vconstraints)

Returns true if the current consumption associated with solution `s` is feasible respect to constraints `vconstraints`.

**Note:** This function DOES NOT compute the current consumption of solution `s`. It just checks the last values saved in memory and compare them with the right-hand side values of the constraints. This is for efficiency reasons. Usually, given a solution `s`, when you locally modified it, it is possible to efficiently recompute the current consumption of the solution by just checking the constraints affected by the change. Therefore, to check feasibility it would be a waste of time to recompute the left-hand sides again instead of checking the values in memory.

If the lhs must be recomputed to check feasibility, use function [`is_feasible(s::OREnvironment.Solution, constraints::Array{<:OREnvironment.Constraint,1})`](@ref) instead.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_current_consumption_feasible(s::Solution, 
                                         constraints::Array{<:Constraint,1})::Bool
    local N::Int = length(constraints);
    @inbounds for i in 1:N
        local lhs::Float64 = get_constraint_consumption(s, i);
        local feasible::Bool = is_feasible(constraints[i], lhs);
        if !feasible
            return false;
        end
    end
    return true;
end 

"""
    compute_lhs(c, s)

Computes the consumption (left-hand side) of constraint `c` by solution `s`.

**Note:** It returns the value of the lhs, but it DOES NOT modified the consumption status of solution `s`.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function compute_lhs(c::Constraint, s::Solution)::Float64
    local lhs::Float64 = 0.0;
    for (variable, coef) in c.variablesPositiveCoefficients
         lhs += coef*get_solution(s, variable);
    end
    for (variable, coef) in c.variablesNegativeCoefficients
         lhs += coef*get_solution(s, variable);
    end
    return lhs;
end

"""
    is_feasible(s, vconstraints)

Returns true if the consumption incurred by solution `s` is feasible respect to constraints `vconstraints`.

**Note:** This function computes the left-hand sides of constraints using `s`, but it DOES NOT update the current consumption of solution `s`.

**Tip:** If the lhs does not have to be recomputed, then check function [`is_current_consumption_feasible`](@ref) for a better performance. Actually, that function should be preferred over `is_feasible(s, vconstraints)`.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_feasible(s::Solution, 
                     constraints::Array{<:Constraint,1})::Bool
    for c in constraints
        local lhs::Float64 = compute_lhs(c, s);
        local feasible::Bool = is_feasible(c, lhs);
        if !feasible
            return false;
        end
    end
    return true;
end

"""
    is_active(c, s)

Returns true if constraint `c` is active under the consumption incurred by solution `s`. 

**Note:** This function computes the left-hand side of the constraint using `s`, but it DOES NOT update the current consumption of solution `s`.

**Tip:** If the lhs does not have to be recomputed, then check function [`is_active_under_current_consumption`](@ref) for a better performance. Actually, that function should be preferred over this one.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
is_active(c::Constraint, s::Solution)::Bool = is_active(c, compute_lhs(c, s));

"""
    is_active_under_current_consumption(c, idx, s)

Returns true if the `idx`-th constraint (`c`) is active under the consumption incurred by solution `s`. 

**Note:** This function DOES NOT compute the current consumption of solution `s`. It just checks the last value saved in memory and compare it with the right-hand side values of the constraint. That is why `idx` must be provided.

If the lhs must be recomputed, use function [`is_active(c::OREnvironment.Constraint, s::OREnvironment.Solution)`](@ref) instead.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_active_under_current_consumption(c::Constraint, idxConstraint::Int, s::Solution)::Bool 
  local lhs::Float64 = get_constraint_consumption(s, idxConstraint);
  return is_active(c, lhs);
end
