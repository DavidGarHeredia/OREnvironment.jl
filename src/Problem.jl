
mutable struct DefaultProblem{T<:Real} <: Problem
  costs::Array{T,1};
  constraints::Array{<:Constraint,1};
  variablesConstraints::Array{Array{Int,1},1};
  objSense::Symbol;
end

function constructProblem(costs::Array{T,1},
                          constraints::Array{<:Constraint,1},
                          objSense::Symbol) where {T<:Real}
  variablesConstraints = get_relationship_variables_constraints(constraints, length(costs));
  return DefaultProblem(costs, constraints, variablesConstraints, objSense);
end

get_cost(p::Problem, pos::Int)             = p.costs[pos];
set_cost!(p::Problem, val::Real, pos::Int) = p.costs[pos] = val;
get_obj_sense(p::Problem)::Symbol          = p.objSense;
set_obj_sense!(p::Problem, val::Symbol)    = p.objSense = val;
get_constraint(p::Problem, pos::Int)       = p.constraints[pos];
get_constraints(p::Problem)                = p.constraints;
get_constraints_of_variable(p::Problem, pos::Int)::Array{Int,1} = p.variablesConstraints[pos];

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

gap(lowerBound::Real, upperBound::Real, objSense::Symbol) = return gap(lowerBound, upperBound, Val(objSense));
gap(lowerBound::Real, upperBound::Real, ::Val{:min}) = return (upperBound-lowerBound)/lowerBound;
gap(lowerBound::Real, upperBound::Real, ::Val{:max}) = return (upperBound-lowerBound)/upperBound;
