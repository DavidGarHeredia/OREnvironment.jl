"""
    inverse_order!(s, var1, var2, p)

For solution `s`, this function reverses the order of the values between `var1` and `var2`. For example, the inverse order of [1.2, 3.4, 6.0, 8.9] is [8.9, 6.0, 3.4, 1.2]. 

The status of the solution (e.g., feasibility) is updated using the information in problem `p`.

# Example
See examples in tests.
"""
function inverse_order!(s::FixedLengthArray{T}, 
                        firstVariable::Int,
                        lastVariable::Int,
                        p::Problem) where {T<:Real}
    local numberOfElements::Int = lastVariable - firstVariable;
    local counter = 0
    for i in 0:2:numberOfElements
        swap_values!(s, firstVariable+counter, lastVariable-counter, p)
        counter += 1
    end
end

"""
    undo_inverse!(s, var1, var2, p)

This function undoes the last called of function `inverse_order`.

# Example
See examples in tests.
"""
function undo_inverse!(s::FixedLengthArray{T}, 
                       firstVariable::Int,
                       lastVariable::Int,
                       p::Problem) where {T<:Real}
    inverse_order!(s, firstVariable, lastVariable, p);
end

"""
    swap_values!(s, var1, var2, p)

For solution `s`, this function changes the values of variables `var1` and `var2`, so the `var1` now takes the value of `var2` and `var2` the value of `var1`.

The status of the solution (e.g., feasibility) is updated using the information in problem `p`.

# Example
See examples in tests.
"""
function swap_values!(s::FixedLengthArray{T}, 
                      variable1::Int,
                      variable2::Int,
                      p::Problem) where {T<:Real}
    local value1::T = get_solution(s, variable1)
    local value2::T = get_solution(s, variable2)
    add_solution_and_update_status!(s, variable2, value1, p);
    add_solution_and_update_status!(s, variable1, value2, p);
end

"""
    undo_swap!(s, var1, var2, p)

This function undoes the last called of function `swap_values`.

# Example
See examples in tests.
"""
function undo_swap!(s::FixedLengthArray{T}, 
                    variable1::Int,
                    variable2::Int,
                    p::Problem) where {T<:Real}
    swap_values!(s, variable1, variable2, p); # doing the swap again undoes the swap
end

"""
    flip_value!(s, var, p)

For solution `s`, this function puts `var` to 0 if it has value 1 and viceversa. If the value of the variable is different than 1 or 0, then nothing happens.

The status of the solution (e.g., feasibility) is updated using the information in problem `p`.

# Example
See examples in tests.
"""
function flip_value!(s::FixedLengthArray{T}, 
                     variable::Int,
                     p::Problem) where {T<:Real}
    local value::T = get_solution(s, variable);
    if value == zero(T)
        add_solution_and_update_status!(s, variable, one(T), p);
    elseif value == one(T)
        add_solution_and_update_status!(s, variable, zero(T), p);
    end
end

"""
    undo_flip!(s, var, p)

This function undoes the last called of function `flip_value`.

# Example
See examples in tests.
"""
function undo_flip!(s::FixedLengthArray{T}, 
                    variable::Int, 
                    p::Problem) where {T<:Real}
    flip_value!(s, variable, p); # if we flip again, we undo the change
end

"""
    mirror_value!(s, var, p)

If variable `var` in solution `s` has a value `x[var]=z`, and the variable is bounded to the interval (it may be discrete) `[lb, ub]`, then the variable is assigned value `ub+lb-z`.

For example, if `x[var]=4` and `[lb, ub] = [1,5]`, then, after calling the function, `x[var] = 2`. Notice that if you draw the bounds in the real line: 1-2-3-4-5, value 2 is the mirror of 4. Meaning that if you fold the interval by its middle point (which in the example is 3), value 2 and 4 would touch.

If the value of the variable is not within its bounds, then nothing happens.

The status of the solution (e.g., feasibility) is updated using the information in problem `p`.

# Example
See examples in tests.
"""
function mirror_value!(s::FixedLengthArray{T}, 
                       variable::Int, 
                       p::Problem) where {T<:Real}
    local value::T = get_solution(s, variable);
    if is_value_within_the_domain(p, variable, value)
        local sumBounds::T = T(get_ub_variable(p, variable) + get_lb_variable(p, variable));
        local newValue::T =  sumBounds - value;
        add_solution_and_update_status!(s, variable, newValue, p);
    end
end

"""
    undo_mirror!(s, var, p)

This function undoes the last called of function `mirror_value`.

# Example
See examples in tests.
"""
function undo_mirror!(s::FixedLengthArray{T}, 
                      variable::Int, 
                      p::Problem) where {T<:Real}
    mirror_value!(s, variable, p); # if we mirror again, we undo the change
end