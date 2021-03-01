############################
# Types & Constructors
############################
mutable struct FixLengthArray{T<:Real} <: Solution
    sol::Array{T,1};
    status::Status;
end

function constructSolution(solutionType::Symbol, args)
    return constructSolution(Val(solutionType), args...);
end

function constructSolution(::Val{:FixLengthArray}, 
                           typeVariables::DataType, 
                           numVariables::Int, 
                           status::Status)
    return FixLengthArray(zeros(typeVariables, numVariables), status);
end


############################
# General methods for Solution
############################
is_feasible(s::Solution)::Bool           = is_feasible(s.status);
set_feasible!(s::Solution, value::Bool)  = set_feasible!(s.status, value);
is_optimal(s::Solution)::Bool            = is_optimal(s.status); 
set_optimal!(s::Solution, value::Bool)   = set_optimal!(s.status, value); 
get_objfunction(s::Solution)::Float64    = get_objfunction(s.status);
set_objfunction!(s::Solution, value::Float64) = set_objfunction!(s.status, value);
get_constraint_consumption(s::Solution, idxConstraint::Int)::Float64 = get_constraint_consumption(s.status, idxConstraint); 
set_constraint_consumption!(s::Solution, idxConstraint::Int, value::Float64) = set_constraint_consumption!(s.status, idxConstraint, value); 

function is_first_solution_better(s1::Solution, 
                                  s2::Solution, 
                                  objSense::Symbol, 
                                  feasibilityRequired::Bool)::Bool
    return is_first_status_better(s1.status, s2.status, objSense, feasibilityRequired);
end

############################
# Specific methods for Solution
############################

get_solution(s::FixLengthArray{T}, variable::Int)            where {T<:Real} = @inbounds s.sol[variable];
add_solution!(s::FixLengthArray{T}, value::T, variable::Int) where {T<:Real} = @inbounds s.sol[variable] = value;
remove_solution!(s::FixLengthArray{T}, variable::Int)        where {T<:Real} = @inbounds s.sol[variable] = zero(T);
function remove_all_solutions!(s::FixLengthArray{T}) where {T<:Real}
    s.sol .= zero(T);
    return nothing;
end

@inline function copy_first_solution_to_second!(s1::FixLengthArray{T}, 
                                                s2::FixLengthArray{T}) where {T<:Real}
    update_status!(s2.status, s1.status); 
    copy!(s2.sol, s1.sol);
    return nothing;
end

############################
# General methods for Solution when dealing with constraints
############################
function update_constraint_consumption!(s::Solution, 
                                        constraints::Array{<:Constraint,1})
    local N::Int = length(constraints);
    @inbounds for i in 1:N 
        local lhs::Float64 = compute_lhs(constraints[i], s);
        set_constraint_consumption!(s, i, lhs);
    end
    return nothing;
end

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

function update_constraint_consumption!(s::Solution, 
                                        constraints::Array{<:Constraint,1}, 
                                        variable::Int, 
                                        Δvariable::Real, 
                                        idxConstraints::Array{Int,1})
    @inbounds for i in idxConstraints
        local currentLHS::Float64 = get_constraint_consumption(s, i);
        local lhs::Float64 = compute_lhs_after_increment(variable, Δvariable, currentLHS, constraints[i]);
        set_constraint_consumption!(s, i, lhs);
    end
    return nothing;
end

function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1}, 
                                                        variable::Int, 
                                                        Δvariable::Real, 
                                                        idxConstraints::Array{Int,1})
    local feasible::Bool = true;
    @inbounds for i in idxConstraints
        local currentLHS::Float64 = get_constraint_consumption(s, i);
        local lhs::Float64 = compute_lhs_after_increment(variable, Δvariable, currentLHS, constraints[i]);
        set_constraint_consumption!(s, i, lhs);
        local isfeasible::Bool = is_feasible(constraints[i], lhs);
        if !isfeasible feasible = false; end
    end

    local globalCheckRequired::Bool = should_global_feasibility_be_checked(is_feasible(s), feasible);
    if globalCheckRequired
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
function add_solution_and_update_status!(s::FixLengthArray{T}, 
                                         value::T, 
                                         variable::Int, 
                                         p::Problem) where {T<:Real}
    @inbounds local Δ::T  = value - s.sol[variable];
    local newObj::Float64 = get_objfunction(s) + Δ*get_cost(p, variable);
    @inbounds s.sol[variable] = value;
    update_constraint_consumption_and_feasibility!(s, get_constraints(p), variable, Δ, 
                                                   get_constraints_of_variable(p, variable));
    set_objfunction!(s, newObj);
    return nothing;
end

function remove_solution_and_update_status!(s::FixLengthArray{T}, 
                                            variable::Int, 
                                            p::Problem) where {T<:Real}
    add_solution_and_update_status!(s, zero(T), variable, p);
    return nothing;
end

function remove_all_solutions_and_update_status!(s::FixLengthArray{T},
                                                 p::Problem) where {T<:Real}
    s.sol .= zero(T);
    set_objfunction!(s, 0.0);
    s.status.constraintLhsConsumption .= 0.0;
    local feasible::Bool = is_current_consumption_feasible(s, get_constraints(p));
    set_feasible!(s, feasible);
    return nothing;
end
