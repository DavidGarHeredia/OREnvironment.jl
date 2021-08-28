
using OREnvironment
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
	# flipping variable 1
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
	# flipping varible 6
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