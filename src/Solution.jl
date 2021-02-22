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
set_feasible!(s::Solution, val::Bool)    = set_feasible!(s.status, val);
is_optimal(s::Solution)::Bool            = is_optimal(s.status); 
set_optimal!(s::Solution, val::Bool)     = set_optimal!(s.status, val); 
get_objfunction(s::Solution)             = get_objfunction(s.status);
set_objfunction!(s::Solution, val::Real) = set_objfunction!(s.status, val);
get_constraint_consumption(s::Solution, pos::Int) = get_constraint_consumption(s.status, pos); 
set_constraint_consumption!(s::Solution, val::Real, pos::Int) = set_constraint_consumption!(s.status, val, pos); 

function is_first_solution_better(s1::Solution, 
                                  s2::Solution, 
                                  objSense::Symbol, 
                                  feasibilityRequired::Bool)::Bool
    return is_first_status_better(s1.status, s2.status, objSense, feasibilityRequired);
end

############################
# Specific methods for Solution
############################

get_solution(s::FixLengthArray{T}, pos::Int)            where {T<:Real} = @inbounds s.sol[pos];
add_solution!(s::FixLengthArray{T}, value::T, pos::Int) where {T<:Real} = @inbounds s.sol[pos] = value;
remove_solution!(s::FixLengthArray{T}, pos::Int)        where {T<:Real} = @inbounds s.sol[pos] = zero(T);
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
        local lhs = compute_lhs(constraints[i], s);
        set_constraint_consumption!(s, lhs, i);
    end
    return nothing;
end

function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1})
    local feasible::Bool = true;
    local N::Int = length(constraints);
    @inbounds for i in 1:N 
        local lhs = compute_lhs(constraints[i], s);
        set_constraint_consumption!(s, lhs, i);
        if !is_feasible(constraints[i], lhs) feasible = false; end
    end
    set_feasible!(s, feasible);
    return nothing;
end

function update_constraint_consumption!(s::Solution, 
                                        constraints::Array{<:Constraint,1}, 
                                        variable::Int, 
                                        Δvariable::Real, 
                                        idxConstraints::Array{Int,1})
    local currentLHS = get_constraint_consumption(s, 1);
    @inbounds for i in idxConstraints
        currentLHS = get_constraint_consumption(s, i);
        local lhs = compute_lhs_after_increment(variable, Δvariable, currentLHS, constraints[i]);
        set_constraint_consumption!(s, lhs, i);
    end
    return nothing;
end

function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1}, 
                                                        variable::Int, 
                                                        Δvariable::Real, 
                                                        idxConstraints::Array{Int,1})
    local feasible::Bool = true;
    local currentLHS = get_constraint_consumption(s, 1);
    @inbounds for i in idxConstraints
        currentLHS = get_constraint_consumption(s, i);
        local lhs = compute_lhs_after_increment(variable, Δvariable, currentLHS, constraints[i]);
        set_constraint_consumption!(s, lhs, i);
        if !is_feasible(constraints[i], lhs) feasible = false; end
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
# function add_solution_and_update_status!(s::FixLengthArray{T}, 
#                                          value::T, 
#                                          pos::Int, 
#                                          p::Problem) where {T<:Real}
#     @inbounds Δ::T = value - s.sol[pos];
#     @inbounds newObj = get_objfunction(s) + Δ*p.costs[pos];
#     @inbounds s.sol[pos] = value;
#     @inbounds update_constraint_consumption_and_feasibility!(s, p.constraints, pos, Δ, 
#                                                              p.variablesConstraints[pos]);
#     set_objfunction!(s, newObj);
#     return nothing;
# end

# function remove_solution_and_update_status!(s::FixLengthArray{T}, 
#                                             pos::Int, 
#                                             p::Problem) where {T<:Real}
#     add_solution_and_update_status!(s, zero(T), pos, p);
#     return nothing;
# end

# function remove_all_solutions_and_update_status!(s::FixLengthArray{T},
#                                                  p::Problem) where {T<:Real}
#     s.sol .= zero(T);
#     set_objfunction!(s, zero(get_objfunction(s)));
#     s.status.constraintLhsConsumption .= zero(eltype(s.status.constraintLhsConsumption));
#     local feasible::Bool = is_current_consumption_feasible(s, p.constraints);
#     set_feasible!(s, feasible);
#     return nothing;
# end
