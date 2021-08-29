# swap two values
# inverse (inverse the order of all elements between x_i and x_j) 
# insert (put element x_j in position i) # check if Julia is faster by default 
# insert_sequence = move a whole seq instead of just one element like insertion

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
		local sum_bounds::T = T(get_ub_variable(p, variable) + get_lb_variable(p, variable));
		local new_value::T =  sum_bounds - value;
		add_solution_and_update_status!(s, variable, new_value, p);
	end
end

function undo_mirror!(s::FixedLengthArray{T}, 
					  variable::Int, 
					  p::Problem) where {T<:Real}
	mirror_value!(s, variable, p); # if we mirror again, we undo the change
end