
mutable struct DefaultConstraint{T<:Real} <: Constraint
    rhs::T;
    type::Symbol;
    variablesPositiveCoefficients::Dict{Int,T}; 
    variablesNegativeCoefficients::Dict{Int,T}; 
end

"""
    constructConstraint(rhs, t, vars, coefs)

Construct a `DefaultConstraint` with right-hand side `rhs`, type `t` and left-hand side given by the variables in `vars` and coefficients in `coefs`.

# Example
```jldoctest
julia> OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
```
"""
function constructConstraint(rhs::T, 
                             constraintType::Symbol, 
                             variables::Array{Int,1}, 
                             coefficients::Array{T,1}) where {T<:Real}
    dictPositive = Dict{Int,T}();
    dictNegative = Dict{Int,T}();
    for i in 1:length(variables)
        if coefficients[i] > 0
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
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.get_rhs(c)
12
```
"""
get_rhs(c::Constraint) = c.rhs;

"""
    set_rhs!(c, val)

Sets the right-hand side value of constraint `c` to `val`

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.set_rhs!(c, 25); 
julia> OREnvironment.get_rhs(c)
25
```
"""
set_rhs!(c::Constraint, val::Real) = c.rhs = val;

"""
    get_type(c)

Returns the constraint type of `c`. Admisible values are :lessOrEq, :equal and :greaterOrEq.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
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
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.set_type!(c, :greaterOrEq);
julia> OREnvironment.get_type(c)
:greaterOrEq
```
"""
set_type!(c::Constraint, val::Symbol) = c.type = val;

"""
    is_variable(c, var)

Returns true if variable `var` is in constraint `c`.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.is_variable(c, 33)
true
julia> OREnvironment.is_variable(c, 13)
false
```
"""
function is_variable(c::Constraint, pos::Int)::Bool
    local answer::Bool = haskey(c.variablesPositiveCoefficients, pos) || 
                         haskey(c.variablesNegativeCoefficients, pos);
   return answer; 
end

"""
    get_coefficient(c, var)

Returns the coefficient of variable `var` in constraint `c`. If the variable is not in the constraint it returns zero(T), where T is the type of the constraint (Int, Float64...).


# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.get_coefficient(c, 33)
1
julia> OREnvironment.get_coefficient(c, 3)
5
```
"""
function get_coefficient(c::Constraint, pos::Int)
    local val = get(c.variablesPositiveCoefficients, pos, zero(typeof(c.rhs)));
    if val == zero(typeof(c.rhs))
        val = get(c.variablesNegativeCoefficients, pos, zero(typeof(c.rhs)));
    end
    return val;
end

"""
   set_coefficient!(c, var, coef)

Sets in constraint `c` coefficient `coef` for variable `var`. If the variable was not in the constraint, it is added to it.

# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 12, 33], [2, 5, 3, 1]);
julia> OREnvironment.set_coefficient!(c, 33, 123);
julia> OREnvironment.get_coefficient(c, 33)
123
```
"""
function set_coefficient!(c::Constraint, pos::Int, val::Real)
    if val > 0
        c.variablesPositiveCoefficients[pos] = val;
    else
        c.variablesNegativeCoefficients[pos] = val;
    end
end

"""
   get_relationship_variables_constraints(vconstraints, nVariables)

Given an Array of constraints `vconstraints` and the number of variables in the problem, returns an Array where the i-th element is an Array with the indexes of the constraints where the i-th variable appears.

This function is employed in the `Problem` struct so it is possible to quickly identfy what constraints in the problem are affected when a variable changes its value. This permits faster updates of the left-hand side value associated to a given solution.

# Example
```jldoctest
julia> c1 = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 4], [2, 5, 3]);
julia> c2 = OREnvironment.constructConstraint(5, :equal, [2, 3, 5], [9, 1, 7]);
julia> constraints = [c1, c2];
julia> nVariables = 5;
julia> OREnvironment.get_relationship_variables_constraints(constraints, nVariables)
5-element Array{Array{Int64,1},1}:
 [1]
 [2]
 [1, 2]
 [1]
 [2]
 # So variable 1 appears in constraint 1, variable 2 in constraint 2 
 # variable 3 in constraints 1 and 2...
```
"""
function get_relationship_variables_constraints(constraints::Array{<:Constraint,1}, 
                                                nVariables::Int)::Array{Array{Int,1}, 1}
    if length(constraints) == 0 return Array{Array{Int,1}, 1}() end
    variablesConstraints = [Int[] for i in 1:nVariables];
    for i in 1:length(constraints)
      add_constraint_index_to_variables!(constraints[i], i, variablesConstraints);
    end
    return variablesConstraints;
end

function add_constraint_index_to_variables!(c::Constraint, 
                                            idx::Int,
                                            variablesConstraints::Array{Array{Int,1}, 1})  
    for variable in keys(c.variablesPositiveCoefficients)
        push!(variablesConstraints[variable], idx);
    end
    for variable in keys(c.variablesNegativeCoefficients)
        push!(variablesConstraints[variable], idx);
    end
    return nothing;
end

"""
    read_constraints(file, typeRHS)

Returns an Array of constraints. The constraints are read from `file`.

See an example in the source file ./test/Constraints.jl
"""
function read_constraints(file::String, Trhs::DataType)
    fileStream = open(file, "r");
    lines = readlines(fileStream);
    constraints = [constructConstraint(zero(Trhs), :equal, Int[], Array{Trhs,1}()) 
                   for i in 1:length(lines)];
    for i in 1:length(lines) # code in parallel!!!
      parse_constraint!(constraints[i], lines[i], Trhs, i);
    end
    return constraints;
end

function parse_constraint!(c::Constraint, line::String, Trhs::DataType, idx::Int)
    local sign = parse_and_set_constraint_sign!(c, line, idx);
    elements = split(line, sign);

    set_rhs!(c, parse(Trhs, elements[2]));

    lhs = split(elements[1], "+");
    for i in 1:length(lhs)
      terms = split(lhs[i], "x");
      coef = parse(Trhs, terms[1]);
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
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 4], [2, 5, 3]);
julia> OREnvironment.is_feasible(c, 6)
true
julia> OREnvironment.is_feasible(c, 16)
false
```
"""
is_feasible(c::Constraint, lhs::Real)::Bool = is_feasible(get_rhs(c), lhs, Val(get_type(c))); 
is_feasible(rhs::Real, lhs::Real, ::Val{:lessOrEq})::Bool    = lhs <= rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:equal})::Bool       = lhs ≈ rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:greaterOrEq})::Bool = lhs >= rhs;

"""
    compute_lhs_after_increment(var, Δ, currentLHS, c)

For a change of `Δ` in the value of variable `var`, returns the new left-hand side consumption in constraint `c` given the current consumption `currentLHS`.


# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 4], [2, 5, 3]);
julia> Δ = 3; currentLHS = 9;
julia> OREnvironment.compute_lhs_after_increment(1, Δ, currentLHS, c)
15 # = Δ*2 + currentLHS
```
"""
function compute_lhs_after_increment(variable::Int, 
                                     Δvariable::Real,
                                     currentLHS::Real, 
                                     c::Constraint)
    local Δconsumption = Δvariable*get_coefficient(c, variable);
    local lhs = currentLHS + Δconsumption; 
    return lhs;
end

"""
    is_increment_feasible(var, Δ, currentLHS, c)

For a change of `Δ` in the value of variable `var`, returns if new left-hand side consumption in constraint `c` is feasible given the current consumption `currentLHS`.
# Example
```jldoctest
julia> c = OREnvironment.constructConstraint(12, :lessOrEq, [1, 3, 4], [2, 5, 3]);
julia> Δ = 3; currentLHS = 9;
julia> OREnvironment.is_increment_feasible(1, Δ, currentLHS, c)
false # new lhs would be 15 which larger than 12
```
"""
function is_increment_feasible(variable::Int, 
                               Δvariable::Real,
                               currentLHS::Real, 
                               c::Constraint)::Bool
    local lhs = compute_lhs_after_increment(variable, Δvariable, currentLHS, c);
    return is_feasible(c, lhs);
end


############################
# General methods for Constraints when dealing with Solutions
############################
"""
  is_increment_feasible(s, vconstraints, var, Δ, idxConstraints)

Given solution `s`, the constraints of the problem `vconstraints`, a change `Δ` in variable `var` and an Array with the constraint indices where variable `var` appears, returns if the change is feasible or not.

**Note:** That the change is feasible DOES NOT mean that the solution is feasible. Given a feasible solution, a feasible change implies that the new solution is still feasible. But given an infeasible solution, a feasible change means that the constraints where `var` appears are not violated by the current change. However, as the original solution was infeasible, the new one is still infeasible. If the return of the function is `false`, then the solution after the change is infeasible, regardless of the original feasibility situation.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_increment_feasible(s::Solution, 
                               constraints::Array{<:Constraint,1}, 
                               variable::Int, 
                               Δvariable::Real, 
                               idxConstraints::Array{Int,1})::Bool
    if length(idxConstraints) == 0 return true end;
    local currentLHS = get_constraint_consumption(s, 1);
    @inbounds for i in idxConstraints
        currentLHS = get_constraint_consumption(s, i);
        if !is_increment_feasible(variable, Δvariable, currentLHS, constraints[i])
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
        local lhs = get_constraint_consumption(s, i);
        if !is_feasible(constraints[i], lhs)
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
function compute_lhs(c::Constraint, s::Solution)
    local lhs = zero(typeof(get_rhs(c)));
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

**Note:** This function computed the left-hand sides of constraints useing `s`, but it DOES NOT update the current consumption of solution `s`.

**Tip:** If the lhs does not have to be recomputed, then check function [`is_current_consumption_feasible`](@ref) for a better performance. Actually, that function should be preferred over `is_feasible(s, vconstraints)`.

See examples in the file with the tests: *./test/Constraints.jl*.
"""
function is_feasible(s::Solution, 
                     constraints::Array{<:Constraint,1})::Bool
    for c in constraints
        local lhs = compute_lhs(c, s);
        if !is_feasible(c, lhs)
            return false;
        end
    end
    return true;
end
