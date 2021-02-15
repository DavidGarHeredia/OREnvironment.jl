############################
# Types & Constructors
############################
Base.@kwdef mutable struct DefaultStatus{T<:Real, G<:Real} <: Status
    feasible::Bool = false;
    optimal::Bool  = false; 
    objfunction::T = zero(T);
    constraintLhsConsumption::Array{G,1};
end

function constructStatus(numberConstraints::Int, 
                         typeObjFunction::DataType, 
                         typeLHS::DataType)
    lhs = zeros(typeLHS, numberConstraints);
    return DefaultStatus{typeObjFunction, typeLHS}(constraintLhsConsumption = lhs);
end

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
# General methods for Status
############################
is_feasible(s::Status)::Bool           = s.feasible;
set_feasible!(s::Status, val::Bool)    = s.feasible = val;
is_optimal(s::Status)::Bool            = s.optimal; 
set_optimal!(s::Status, val::Bool)     = s.optimal = val; 
get_objfunction(s::Status)             = s.objfunction;
set_objfunction!(s::Status, val::Real) = s.objfunction = val;
get_constraint_consumption(s::Status, pos::Int) = @inbounds s.constraintLhsConsumption[pos];
set_constraint_consumption!(s::Status, val::Real, pos::Int) = @inbounds s.constraintLhsConsumption[pos] = val;

worst_value(objsense::Symbol, T::DataType) = worst_value(Val(objsense), T);
worst_value(::Val{:max}, T::DataType) = typemin(T);
worst_value(::Val{:min}, T::DataType) = typemax(T);

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

function update_constraint_consumption_and_feasibility!(s::Solution, 
                                                        constraints::Array{<:Constraint,1}, 
                                                        variable::Int, 
                                                        Δvariable::Real, 
                                                        idxConstraints::Array{Int,1})
    local feasible::Bool = true;
    @inbounds for i in idxConstraints
        local lhs = compute_lhs_increment(s, constraints[i], i, variable, Δvariable);
        set_constraint_consumption!(s, lhs, i);
        if !is_feasible(constraints[i], lhs) feasible = false; end
    end
    if !is_feasible(s) && feasible
        # if the solution was not already feasible but the current movement is,
        # then feasibility must be set checking all the constraints.
        feasible = is_current_consumption_feasible(s, constraints);
    end
    set_feasible!(s, feasible); 
    return nothing;
end

############################
# Specific methods for Status
############################
function update_solution_status!(s::Solution, 
                                 st::DefaultStatus{T,G}) where {T<:Real, G<:Real}
    set_objfunction!(s, get_objfunction(st));
    set_feasible!(s, is_feasible(st));
    set_optimal!(s, is_optimal(st)); 
    copy!(s.status.constraintLhsConsumption, st.constraintLhsConsumption);
    return nothing;
end

############################
# Specific methods for Solution
############################
function add_solution_and_update_status!(s::FixLengthArray{T}, 
                                         value::T, 
                                         pos::Int, 
                                         p::Problem) where {T<:Real}
    @inbounds Δ::T = value - s.sol[pos];
    @inbounds newObj = get_objfunction(s) + Δ*p.costs[pos];
    @inbounds s.sol[pos] = value;
    @inbounds update_constraint_consumption_and_feasibility!(s, p.constraints, pos, Δ, 
                                                             p.variablesConstraints[pos]);
    set_objfunction!(s, newObj);
    return nothing;
end

function remove_solution_and_update_status!(s::FixLengthArray{T}, 
                                            pos::Int, 
                                            p::Problem) where {T<:Real}
    add_solution_and_update_status!(s, zero(T), pos, p);
    return nothing;
end

function remove_all_solutions_and_update_status!(s::FixLengthArray{T},
                                                 p::Problem) where {T<:Real}
    s.sol .= zero(T);
    set_objfunction!(s, zero(get_objfunction(s)));
    s.status.constraintLhsConsumption .= zero(eltype(s.status.constraintLhsConsumption));
    local feasible::Bool = is_current_consumption_feasible(s, p.constraints);
    set_feasible!(s, feasible);
    return nothing;
end

get_solution(s::FixLengthArray{T}, pos::Int)            where {T<:Real} = @inbounds s.sol[pos];
add_solution!(s::FixLengthArray{T}, value::T, pos::Int) where {T<:Real} = @inbounds s.sol[pos] = value;
remove_solution!(s::FixLengthArray{T}, pos::Int)        where {T<:Real} = @inbounds s.sol[pos] = zero(T);
function remove_all_solutions!(s::FixLengthArray{T}) where {T<:Real}
    s.sol .= zero(T);
    return nothing;
end

@inline function copy_first_solution_to_second!(s1::FixLengthArray{T}, s2::FixLengthArray{T}) where {T<:Real}
    update_solution_status!(s2, s1.status); 
    copy!(s2.sol, s1.sol);
    return nothing;
end