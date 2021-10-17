
using OREnvironment
using ORInterface
using Test

function constructorProblem()
  	cost = collect(1.0:6.0);
  	variables1 = [1, 3, 4, 6];
  	variables2 = [1, 3, 5, 6];
  	coefs1 = [2.3, 3.2, 3.1, 12.34];
  	coefs2 = coefs1 .+ 1.0;
  	constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefs1);
  	constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefs2);
  	constraints = [constraint1, constraint2];
  	variablesConstraints = [[1,2], Int[], [1,2], [1], [2], [1,2]];
  	domain = [OREnvironment.VariableDomain(0.0, 5.0) for i in 1:6]
  	p = OREnvironment.DefaultProblem(cost, constraints, variablesConstraints, :max, domain);
	return p
end

@testset "flip_value and undo_flip" begin
	p = constructorProblem()
	@testset "flipping variable 1" begin
		for type in [Int, Float64]
			sol1 = OREnvironment.create_empty_solution(p, type)
			@test OREnvironment.is_feasible(sol1) == false # by default is false
			@test OREnvironment.get_objfunction(sol1) == 0.0
			@test OREnvironment.get_solution(sol1, 1) == zero(type)

			OREnvironment.flip_value!(sol1, 1, p)
			@test OREnvironment.is_feasible(sol1) == true
			@test OREnvironment.get_objfunction(sol1) == 1.0
			@test OREnvironment.get_solution(sol1, 1) == one(type)
			
			OREnvironment.undo_flip!(sol1, 1, p)
			@test OREnvironment.is_feasible(sol1) == true
			@test OREnvironment.get_objfunction(sol1) == 0.0
			@test OREnvironment.get_solution(sol1, 1) == zero(type)
			
			OREnvironment.add_solution!(sol1, 1, 3*one(type))
			OREnvironment.flip_value!(sol1, 1, p) # as we don't have 1 or 0 nothing happens
			@test OREnvironment.get_solution(sol1, 1) == 3*one(type)
		end
	end

	@testset "flipping varible 6" begin
		for type in [Int, Float64]
			sol1 = OREnvironment.create_empty_solution(p, type)
			@test OREnvironment.is_feasible(sol1) == false # by default is false
			@test OREnvironment.get_objfunction(sol1) == 0.0
			@test OREnvironment.get_solution(sol1, 6) == zero(type)

			OREnvironment.flip_value!(sol1, 6, p)
			@test OREnvironment.is_feasible(sol1) == false
			@test OREnvironment.get_objfunction(sol1) == 6.0
			@test OREnvironment.get_solution(sol1, 6) == one(type)

			OREnvironment.undo_flip!(sol1, 6, p)
			@test OREnvironment.is_feasible(sol1) == true
			@test OREnvironment.get_objfunction(sol1) == 0.0
			@test OREnvironment.get_solution(sol1, 6) == zero(type)

			OREnvironment.add_solution!(sol1, 6, 3*one(type))
			OREnvironment.flip_value!(sol1, 6, p) # as we don't have 1 or 0 nothing happens
			@test OREnvironment.get_solution(sol1, 6) == 3*one(type)
		end
	end
end

@testset "mirror_value! and undo_mirror" begin
	p = constructorProblem()
	@testset "0 as lb and Float64 as a type" begin
		sol1 = OREnvironment.create_empty_solution(p, Float64)
		@test OREnvironment.get_solution(sol1, 1) == 0.0
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 1.75, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.25
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.75

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2.5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.5

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3.5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.5

		OREnvironment.add_solution_and_update_status!(sol1, 1, 4.75, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0.25
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4.75

		OREnvironment.add_solution_and_update_status!(sol1, 1, 5.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5.0
	end
	@testset "0 as lb and Int as a type" begin
		sol1 = OREnvironment.create_empty_solution(p, Int)
		@test OREnvironment.get_solution(sol1, 1) == 0
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 1, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3

		OREnvironment.add_solution_and_update_status!(sol1, 1, 4, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4

		OREnvironment.add_solution_and_update_status!(sol1, 1, 5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5
	end

	OREnvironment.set_lb_variable!(p, 1, 1.0)
	@testset "1 as lb and Float as a type" begin
		sol1 = OREnvironment.create_empty_solution(p, Float64)
		@test OREnvironment.get_solution(sol1, 1) == 0.0 # value outside bounds
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0.0 # we did nothing
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 1.75, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4.25
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.75

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2.5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.5

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3.5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2.5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3.5

		OREnvironment.add_solution_and_update_status!(sol1, 1, 4.75, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.25
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4.75

		OREnvironment.add_solution_and_update_status!(sol1, 1, 5.0, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.0
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5.0
	end
	@testset "1 as lb and Int as a type" begin
		sol1 = OREnvironment.create_empty_solution(p, Int)
		@test OREnvironment.get_solution(sol1, 1) == 0 # value outside bounds
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0 # we did nothing
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 0

		OREnvironment.add_solution_and_update_status!(sol1, 1, 1, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1

		OREnvironment.add_solution_and_update_status!(sol1, 1, 2, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2

		OREnvironment.add_solution_and_update_status!(sol1, 1, 3, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 3

		OREnvironment.add_solution_and_update_status!(sol1, 1, 4, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 2
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 4

		OREnvironment.add_solution_and_update_status!(sol1, 1, 5, p)
		OREnvironment.mirror_value!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 1
		OREnvironment.undo_mirror!(sol1, 1, p)
		@test OREnvironment.get_solution(sol1, 1) == 5
	end
end


@testset "swap_values and undo_swap" begin
	p = constructorProblem()
	sol1 = OREnvironment.create_empty_solution(p, Int)
	@test OREnvironment.get_solution(sol1, 1) == 0
	@test OREnvironment.get_solution(sol1, 2) == 0 
	OREnvironment.add_solution!(sol1, 1, 4)
	OREnvironment.add_solution!(sol1, 2, 3)
	@test OREnvironment.get_solution(sol1, 1) == 4
	@test OREnvironment.get_solution(sol1, 2) == 3 
	OREnvironment.swap_values!(sol1, 1, 2, p)
	@test OREnvironment.get_solution(sol1, 1) == 3
	@test OREnvironment.get_solution(sol1, 2) == 4 
	OREnvironment.undo_swap!(sol1, 1, 2, p)
	@test OREnvironment.get_solution(sol1, 1) == 4
	@test OREnvironment.get_solution(sol1, 2) == 3 
end

@testset "inverse_order and undo_inverse" begin
	p = constructorProblem()
	sol1 = OREnvironment.create_empty_solution(p, Float64)
	OREnvironment.add_solution!(sol1, 1, 1.6)
	OREnvironment.add_solution!(sol1, 2, 2.5)
	OREnvironment.add_solution!(sol1, 3, 3.4)
	OREnvironment.add_solution!(sol1, 4, 4.3)
	OREnvironment.add_solution!(sol1, 5, 5.2)
	OREnvironment.add_solution!(sol1, 6, 6.1)
	@test OREnvironment.get_solution(sol1, 1) == 1.6 
	@test OREnvironment.get_solution(sol1, 2) == 2.5
	@test OREnvironment.get_solution(sol1, 3) == 3.4 
	@test OREnvironment.get_solution(sol1, 4) == 4.3
	@test OREnvironment.get_solution(sol1, 5) == 5.2 
	@test OREnvironment.get_solution(sol1, 6) == 6.1 
	@testset "when the number of elements is even" begin
		OREnvironment.inverse_order!(sol1, 2, 5, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.6 
		@test OREnvironment.get_solution(sol1, 2) == 5.2 
		@test OREnvironment.get_solution(sol1, 3) == 4.3 
		@test OREnvironment.get_solution(sol1, 4) == 3.4
		@test OREnvironment.get_solution(sol1, 5) == 2.5 
		@test OREnvironment.get_solution(sol1, 6) == 6.1 
		OREnvironment.undo_inverse!(sol1, 2, 5, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.6 
		@test OREnvironment.get_solution(sol1, 2) == 2.5
		@test OREnvironment.get_solution(sol1, 3) == 3.4 
		@test OREnvironment.get_solution(sol1, 4) == 4.3
		@test OREnvironment.get_solution(sol1, 5) == 5.2 
		@test OREnvironment.get_solution(sol1, 6) == 6.1 
	end
	@testset "when the number of elements is odd" begin
		OREnvironment.inverse_order!(sol1, 2, 6, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.6 
		@test OREnvironment.get_solution(sol1, 2) == 6.1
		@test OREnvironment.get_solution(sol1, 3) == 5.2
		@test OREnvironment.get_solution(sol1, 4) == 4.3
		@test OREnvironment.get_solution(sol1, 5) == 3.4
		@test OREnvironment.get_solution(sol1, 6) == 2.5
		OREnvironment.undo_inverse!(sol1, 2, 6, p)
		@test OREnvironment.get_solution(sol1, 1) == 1.6 
		@test OREnvironment.get_solution(sol1, 2) == 2.5
		@test OREnvironment.get_solution(sol1, 3) == 3.4 
		@test OREnvironment.get_solution(sol1, 4) == 4.3
		@test OREnvironment.get_solution(sol1, 5) == 5.2 
		@test OREnvironment.get_solution(sol1, 6) == 6.1 
	end
end