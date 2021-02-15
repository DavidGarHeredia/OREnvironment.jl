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
# Specific methods for Status
############################
function update_status!(oldStatus::DefaultStatus{T,G},
                        newStatus::DefaultStatus{T,G}) where {T<:Real, G<:Real}
    set_objfunction!(oldStatus, get_objfunction(newStatus));
    set_feasible!(oldStatus, is_feasible(newStatus));
    set_optimal!(oldStatus, is_optimal(newStatus)); 
    copy!(oldStatus.constraintLhsConsumption, newStatus.constraintLhsConsumption);
    return nothing;
end