mutable struct VariableDomain
    lb::Float64;
    ub::Float64;
end

"""
    get_lb(domain)

Returns the lower bound in `domain`

# Example
```jldoctest
julia> domain = OREnvironment.VariableDomain(1.0,5.0);
julia> OREnvironment.get_lb(domain)
1.0
```
"""
get_lb(d::VariableDomain)::Float64 = d.lb;

"""
    set_lb!(domain, val)

Sets the lower bound in `domain` to `val`

# Example
```jldoctest
julia> domain = OREnvironment.VariableDomain(1.0,5.0);
julia> set_lb!(domain, 3.0)
julia> OREnvironment.get_lb(domain)
3.0
```
"""
set_lb!(d::VariableDomain, lb::Float64) = d.lb = lb;

"""
    get_ub(domain)

Returns the upper bound in `domain`

# Example
```jldoctest
julia> domain = OREnvironment.VariableDomain(1.0,5.0);
julia> OREnvironment.get_ub(domain)
5.0
```
"""
get_ub(d::VariableDomain)::Float64 = d.ub;

"""
    set_ub!(domain, val)

Sets the upper bound in `domain` to `val`

# Example
```jldoctest
julia> domain = OREnvironment.VariableDomain(1.0,5.0);
julia> set_ub!(domain, 9.0)
julia> OREnvironment.get_lb(domain)
9.0
```
"""
set_ub!(d::VariableDomain, ub::Float64) = d.ub = ub;

"""
    is_value_within_the_domain(domain, val)

Checks if `val` is between the lower and upper bound of `domain`.

# Example
```jldoctest
julia> domain = OREnvironment.VariableDomain(1.0,5.0);
julia> OREnvironment.is_value_within_the_domain(domain, 3.0)
true
julia> OREnvironment.is_value_within_the_domain(domain, 5)
true
julia> OREnvironment.is_value_within_the_domain(domain, 6)
false
```
"""
@inline function is_value_within_the_domain(d::VariableDomain, value::T)::Bool where {T<:Real}
    return d.lb <= value <= d.ub;
end

"""
    is_solution_within_bounds(arrayDomains, solution)

Checks if all the values of `solution` are within the domains. Each variable will have 1 domain.
"""
function is_solution_within_bounds(variablesDomain::Array{VariableDomain,1},
                                   solution::Solution)::Bool
    local nVariables::Int = length(variablesDomain);
    for i in 1:nVariables
        local value = get_solution(solution, i);
        local feasible::Bool = is_value_within_the_domain(variablesDomain[i], value);
        if feasible == false return false end
    end
    return true;
end


mutable struct DefaultProblem <: Problem
    costs::Array{Float64,1};
    constraints::Array{<:Constraint,1};
    variablesConstraints::Array{Array{Int,1},1};
    objSense::Symbol;
    variablesDomain::Array{VariableDomain,1};
end

"""
    constructProblem(c, vconstr, objSense, vdomains)

Constructs a `DefaultProblem` struct by providing the vector of cost coefficients `c`, the vector of constraint of the problem `vconstr`, the objective sense, and the vector of domains of the variables.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> OREnvironment.constructProblem(cost, constraints, :max, domain)
```
"""
function constructProblem(costs::Array{Float64,1},
                          constraints::Array{<:Constraint,1},
                          objSense::Symbol,
                          domain::Array{VariableDomain,1}) 
    variablesConstraints = get_relationship_variables_constraints(constraints, length(costs));
    return DefaultProblem(costs, constraints, variablesConstraints, objSense, domain);
end

"""
    get_lb_variable(p, var)

Returns the lower bound of variable `var`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_lb_variable(p, 1);
0.0
```
"""
get_lb_variable(p::Problem, variable::Int)::Float64 = get_lb(p.variablesDomain[variable]);

"""
    set_lb_variable!(p, var, val)

Set the lower bound of variable `var` to value `val`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.set_lb_variable!(p, 1, 1.0);
julia> OREnvironment.get_lb_variable(p, 1);
1.0
```
"""
@inline function set_lb_variable!(p::Problem, variable::Int, lb::Float64) 
    set_lb!(p.variablesDomain[variable], lb);
end

"""
    get_ub_variable(p, var)

Returns the upper bound of variable `var`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_ub_variable(p, 1);
1.0
```
"""
get_ub_variable(p::Problem, variable::Int)::Float64 = get_ub(p.variablesDomain[variable]);

"""
    set_ub_variable!(p, var, val)

Set the upper bound of variable `var` to value `val`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.set_ub_variable!(p, 1, 3.0);
julia> OREnvironment.get_ub_variable(p, 1);
3.0
```
"""
@inline function set_ub_variable!(p::Problem, variable::Int, ub::Float64) 
    set_ub!(p.variablesDomain[variable], ub);
end

"""
    get_number_of_variables(p)

Returns the number of variables in problem `p`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_number_of_variables(p);
6
```
"""
get_number_of_variables(p::Problem)::Int = length(p.costs)

"""
    get_number_of_constraints(p)

Returns the number of constraints in problem `p`. This does not include variables bounds.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_number_of_constraints(p);
2
```
"""
get_number_of_constraints(p::Problem)::Int = length(p.constraints)

"""
    get_cost(p, var)

Returns the cost coefficient of variable `var`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_cost(p, 1);
1.0
```
"""
get_cost(p::Problem, variable::Int)::Float64 = @inbounds p.costs[variable];

"""
    set_cost!(p, var, coef)

Sets `coef` as cost coefficient of variable `var`.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.set_cost!(p, 1, 1.5);
julia> OREnvironment.get_cost(p, 1);
1.5
```
"""
set_cost!(p::Problem, variable::Int, value::Float64) = @inbounds p.costs[variable] = value;

"""
    get_obj_sense(p)

Returns the objetive sense of the problem.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_obj_sense(p);
:max
```
"""
get_obj_sense(p::Problem)::Symbol = p.objSense;

"""
    set_obj_sense!(p, objSense)

Sets `objSense` as the objetive sense of the problem.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.set_obj_sense!(p, :min);
julia> OREnvironment.get_obj_sense(p);
:min
```
"""
set_obj_sense!(p::Problem, value::Symbol) = p.objSense = value;

"""
    get_constraint(p, i)

Returns the i-th constraint of the problem.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_constraint(p, 1)
```
"""
get_constraint(p::Problem, idxConstraint::Int) = @inbounds p.constraints[idxConstraint];

"""
    get_constraints(p)

Returns the constraints of the problem.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_constraints(p)
```
"""
get_constraints(p::Problem) = p.constraints;

"""
    get_constraints_of_variable(p, var)

Returns the indexes of the constraints where variable `var` appears in the problem.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.get_constraints_of_variable(p, 1)
[1, 2] # variable 1 appears in both constraints
``` 
"""
get_constraints_of_variable(p::Problem, variable::Int)::Array{Int,1} = @inbounds p.variablesConstraints[variable];

"""
    add_constraint!(p, c)

Adds constraint `c` to problem `p`. It is also possible to provide a vector of constraints instead of a single constraint.

**Note:** The vector indicating which variables appears in which constraints is also updated here.

# Example
```jldoctest
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> c = OREnvironment.constructConstraint(3.9, :equal, [5, 6], [1.4, 11.0]);
julia> OREnvironment.add_constraint!(p, c);
``` 
"""
function add_constraint!(p::Problem, c::Constraint) 
    push!(p.constraints, c);
    local idx::Int = length(p.constraints);
    add_constraint_index_to_variables!(c, idx, p.variablesConstraints);
end

function add_constraint!(p::Problem, constraints::Array{<:Constraint,1}) 
    for c in constraints
        add_constraint!(p,c);
    end
end

"""
    is_feasible(p, s)

Checks if the current status of solution `s` is feasible for problem `p`, regarding constraints and variables bounds. 

**Note:** This function DOES NOT compute the current consumption of solution `s`. It just checks the last values saved in memory and compare them with the right-hand side values of the constraints. 

# Example
```jldoctest
julia> typeVariables = Int; numVariables = 6;  numConstraints = 2;
julia> status = OREnvironment.constructStatus(numConstraints);
julia> args = (typeVariables, numVariables, status);
julia> s = OREnvironment.constructSolution(:FixedLengthArray, args)
julia> cost = collect(1.0:6.0);
julia> variables1 = [1, 3, 4, 6];
julia> variables2 = [1, 3, 5, 6];
julia> coefs1 = [2.3, 3.2, 3.1, 12.34];
julia> coefs2 = coefs1 .+ 1.0;
julia> constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
julia> constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
julia> constraints = [constraint1, constraint2];
julia> domain = [OREnvironment.VariableDomain(0.0,1.0) for i in 1:6];
julia> p = OREnvironment.constructProblem(cost, constraints, :max, domain);
julia> OREnvironment.is_feasible(p,s)
true
julia> OREnvironment.add_solution!(s, 1, 2) # value 2 violates domain
julia> OREnvironment.is_feasible(p,s)
false
``` 
"""
function is_feasible(p::Problem, s::Solution)::Bool
    local lhsFeasible::Bool = is_current_consumption_feasible(s, p.constraints);
    if lhsFeasible == false 
        set_feasible!(s, false);
        return false; 
    end
    local boundFeasible::Bool = is_solution_within_bounds(p.variablesDomain, s);
    set_feasible!(s, boundFeasible);
    return boundFeasible;
end

"""
    gap(LB, UB, objSense) 

Returns the gap between the lower bound `LB` and the upper bound `UB`. The computation changes depending on the objective sense of the problem.

# Example
```jldoctest
julia> LB = 7.0;
julia> UB = 9.0;
julia> OREnvironment.gap(LB, UB, :min) == (UB-LB)/LB
true
julia> OREnvironment.gap(LB, UB, :max) == (UB-LB)/UB
true
``` 
"""
gap(lowerBound::Float64, upperBound::Float64, objSense::Symbol)::Float64 = return gap(lowerBound, upperBound, Val(objSense));
gap(lowerBound::Float64, upperBound::Float64, ::Val{:min})::Float64 = return (upperBound-lowerBound)/lowerBound;
gap(lowerBound::Float64, upperBound::Float64, ::Val{:max})::Float64 = return (upperBound-lowerBound)/upperBound;
