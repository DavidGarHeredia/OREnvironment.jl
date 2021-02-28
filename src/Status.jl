############################
# Types & Constructors
############################
Base.@kwdef mutable struct DefaultStatus <: Status
    feasible::Bool = false;
    optimal::Bool  = false; 
    objfunction::Float64 = 0.0;
    constraintLhsConsumption::Array{Float64,1};
end

function constructStatus(numberConstraints::Int)
    return DefaultStatus(constraintLhsConsumption = zeros(Float64, numberConstraints));
end

############################
# General methods for Status
############################
is_feasible(s::Status)::Bool           = s.feasible;
set_feasible!(s::Status, value::Bool)  = s.feasible = value;
is_optimal(s::Status)::Bool            = s.optimal; 
set_optimal!(s::Status, value::Bool)   = s.optimal = value; 
get_objfunction(s::Status)::Float64    = s.objfunction;
set_objfunction!(s::Status, value::Float64) = s.objfunction = value;
get_constraint_consumption(s::Status, idxConstraint::Int)::Float64 = @inbounds s.constraintLhsConsumption[idxConstraint];
set_constraint_consumption!(s::Status, idxConstraint::Int, value::Float64) = @inbounds s.constraintLhsConsumption[idxConstraint] = value;

worst_value(objsense::Symbol)::Float64 = worst_value(Val(objsense));
worst_value(::Val{:max})::Float64 = typemin(Float64);
worst_value(::Val{:min})::Float64 = typemax(Float64);

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
function update_status!(oldStatus::DefaultStatus,
                        newStatus::DefaultStatus)
    set_objfunction!(oldStatus, get_objfunction(newStatus));
    set_feasible!(oldStatus, is_feasible(newStatus));
    set_optimal!(oldStatus, is_optimal(newStatus)); 
    copy!(oldStatus.constraintLhsConsumption, newStatus.constraintLhsConsumption);
    return nothing;
end
