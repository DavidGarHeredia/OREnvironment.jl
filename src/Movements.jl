# symmetric value... like flip but from lb to ub
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

# function mirror_value!(s::FixedLengthArray{T}, 
# 					   variable::Int, 
# 					   p::Problem) where {T<:Real}
	
# end