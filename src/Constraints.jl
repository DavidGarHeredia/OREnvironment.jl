
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

is_feasible(c::Constraint, lhs::Real)::Bool = is_feasible(get_rhs(c), lhs, Val(get_type(c))); 
is_feasible(rhs::Real, lhs::Real, ::Val{:lessOrEq})::Bool    = lhs <= rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:equal})::Bool       = lhs ≈ rhs;
is_feasible(rhs::Real, lhs::Real, ::Val{:greaterOrEq})::Bool = lhs >= rhs;


function compute_lhs_after_increment(variable::Int, 
                                     Δvariable::Real,
                                     currentLHS::Real, 
                                     c::Constraint)
    local Δconsumption = Δvariable*get_coefficient(c, variable);
    local lhs = currentLHS + Δconsumption; 
    return lhs;
end

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
