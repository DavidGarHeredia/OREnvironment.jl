
mutable struct DefaultProblem <: Problem
  costs::Array{Float64,1};
  constraints::Array{<:Constraint,1};
  variablesConstraints::Array{Array{Int,1},1};
  objSense::Symbol;
end

function constructProblem(costs::Array{Float64,1},
                          constraints::Array{<:Constraint,1},
                          objSense::Symbol) 
  variablesConstraints = get_relationship_variables_constraints(constraints, length(costs));
  return DefaultProblem(costs, constraints, variablesConstraints, objSense);
end

get_cost(p::Problem, variable::Int)::Float64         = p.costs[variable];
set_cost!(p::Problem, value::Float64, variable::Int) = p.costs[variable] = value;
get_obj_sense(p::Problem)::Symbol         = p.objSense;
set_obj_sense!(p::Problem, value::Symbol) = p.objSense = value;
get_constraint(p::Problem, idxConstraint::Int) = p.constraints[idxConstraint];
get_constraints(p::Problem) = p.constraints;
get_constraints_of_variable(p::Problem, idxConstraint::Int)::Array{Int,1} = p.variablesConstraints[idxConstraint];

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

gap(lowerBound::Float64, upperBound::Float64, objSense::Symbol)::Float64 = return gap(lowerBound, upperBound, Val(objSense));
gap(lowerBound::Float64, upperBound::Float64, ::Val{:min})::Float64 = return (upperBound-lowerBound)/lowerBound;
gap(lowerBound::Float64, upperBound::Float64, ::Val{:max})::Float64 = return (upperBound-lowerBound)/upperBound;
