# insert (put element x_j in position i) # check if Julia is faster by default 
# insert_sequence = move a whole seq instead of just one element like insertion

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

function undo_inverse!(s::FixedLengthArray{T}, 
					   firstVariable::Int,
					   lastVariable::Int,
					   p::Problem) where {T<:Real}
	inverse_order!(s, firstVariable, lastVariable, p);
end

function swap_values!(s::FixedLengthArray{T}, 
					  variable1::Int,
					  variable2::Int,
					  p::Problem) where {T<:Real}
	local value1::T = get_solution(s, variable1)
	local value2::T = get_solution(s, variable2)
	add_solution_and_update_status!(s, variable2, value1, p);
	add_solution_and_update_status!(s, variable1, value2, p);
end

function undo_swap!(s::FixedLengthArray{T}, 
					variable1::Int,
					variable2::Int,
					p::Problem) where {T<:Real}
	swap_values!(s, variable1, variable2, p); # doing the swap again undoes the swap
end

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

function undo_flip!(s::FixedLengthArray{T}, 
					variable::Int, 
					p::Problem) where {T<:Real}
	flip_value!(s, variable, p); # if we flip again, we undo the change
end

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

function undo_mirror!(s::FixedLengthArray{T}, 
					  variable::Int, 
					  p::Problem) where {T<:Real}
	mirror_value!(s, variable, p); # if we mirror again, we undo the change
end