
mutable struct DefaultConstraint{T<:Real} <: Constraint
    rhs::T;
    type::Symbol;
    variablesPositiveCoefficients::Dict{Int,T}; 
    variablesNegativeCoefficients::Dict{Int,T}; 
end

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

get_rhs(c::Constraint)                = c.rhs;
set_rhs!(c::Constraint, val::Real)    = c.rhs = val;
get_type(c::Constraint)::Symbol       = c.type;
set_type!(c::Constraint, val::Symbol) = c.type = val;

function is_variable(c::Constraint, pos::Int)::Bool
    local answer::Bool = haskey(c.variablesPositiveCoefficients, pos) || 
                         haskey(c.variablesNegativeCoefficients, pos);
   return answer; 
end

function set_coefficient!(c::Constraint, pos::Int, val::Real)
    if val > 0
        c.variablesPositiveCoefficients[pos] = val;
    else
        c.variablesNegativeCoefficients[pos] = val;
    end
end

function get_coefficient(c::Constraint, pos::Int)
    local val = get(c.variablesPositiveCoefficients, pos, zero(typeof(c.rhs)));
    if val == zero(typeof(c.rhs))
        val = get(c.variablesNegativeCoefficients, pos, zero(typeof(c.rhs)));
    end
    return val;
end

function get_relationship_variables_constraints(constraints::Array{<:Constraint,1}, 
                                                nVariables::Int)
    if length(constraints) == 0 return Array{Array{Int,1}, 1}() end
    variablesConstraints = [Int[] for i in 1:nVariables];
    for i in 1:length(constraints)
        for variable in keys(constraints[i].variablesPositiveCoefficients)
            push!(variablesConstraints[variable], i);
        end
        for variable in keys(constraints[i].variablesNegativeCoefficients)
            push!(variablesConstraints[variable], i);
        end
    end
    return variablesConstraints;
end

is_feasible(c::Constraint, lhs::Real)::Bool = is_feasible(get_rhs(c), lhs, Val(get_type(c))); 
is_feasible(rhs::Real, lhs::Real, ::Val{:lessOrEq})::Bool    = lhs <= rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:equal})::Bool       = lhs ≈ rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:greaterOrEq})::Bool = lhs >= rhs;