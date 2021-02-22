using OREnvironment
using Test

#######################
# PRELIMINARIES FOR THE TESTS 
#######################
mutable struct MyProblem{T<:Real} <: OREnvironment.Problem 
    costs::Array{T,1};
    constraints::Array{<:OREnvironment.Constraint,1};
    variablesConstraints::Array{Array{Int,1},1};
end

function constructorProblem()
    cost = collect(1.0:6.0);

    variables1 = [1, 3, 4, 6];
    variables2 = [1, 3, 5, 6];
    coefficients1 = [2.3, 3.2, 3.1, 12.34];
    coefficients2 = coefficients1 .+ 1.0; 
    constraint1 = OREnvironment.constructConstraint(15.0, :lessOrEq, variables1, coefficients1); 
    constraint2 = OREnvironment.constructConstraint(9.0, :lessOrEq, variables2, coefficients2); 
    constraints = [constraint1, constraint2];

    variablesConstraints = [[1,2], Int[], [1,2], [1], [2], [1,2]];

    return MyProblem(cost, constraints, variablesConstraints);
end

function constructorSolution(numConstraints=2)
    Tobj = Float64; Tconstraints = Float64;
    status = OREnvironment.constructStatus(numConstraints, Tobj, Tconstraints);
    Tvariables = Float64; sizeArray = 6;
    sol  = OREnvironment.constructSolution(:FixLengthArray, (Tvariables, sizeArray, status));
    return sol;
end

# function constructorProblemNegative()
#     cost = collect(1.0:6.0);

#     variables1 = [1, 3, 4, 6];
#     variables2 = [1, 3, 5, 6];
#     coefficients1 = -[2.3, 3.2, 3.1, 12.34];
#     coefficients2 = coefficients1 .- 1.0; 
#     constraint1 = OREnvironment.constructConstraint(15.0, :greaterOrEq, variables1, coefficients1); 
#     constraint2 = OREnvironment.constructConstraint(9.0, :greaterOrEq, variables2, coefficients2); 
#     constraints = [constraint1, constraint2];

#     variablesConstraints = [[1,2], Int[], [1,2], [1], [2], [1,2]];

#     return MyProblem(cost, constraints, variablesConstraints);
# end



#######################
# TESTS 
#######################
@testset "Building Solution" begin
    @testset "FixLengthArray" begin
        numConstraints = 5; Tobj = Float64; Tconstraints = Float64;
        sol = constructorSolution(numConstraints);

        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.is_optimal(sol) == false;
        @test OREnvironment.get_objfunction(sol) == zero(Tobj);
        for i in 1:numConstraints
            @test OREnvironment.get_constraint_consumption(sol, i) == 0.0;
        end

        OREnvironment.set_feasible!(sol, true);
        OREnvironment.set_optimal!(sol, true);
        OREnvironment.set_objfunction!(sol, 16.0);
        for i in 1:numConstraints
            OREnvironment.set_constraint_consumption!(sol, 12.0, i);
        end
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.is_optimal(sol) == true;
        @test OREnvironment.get_objfunction(sol) == 16.0;
        for i in 1:numConstraints
            @test OREnvironment.get_constraint_consumption(sol, i) == 12.0;
        end

        st = OREnvironment.constructStatus(numConstraints, Tobj, Tconstraints);
        OREnvironment.set_feasible!(st, false);
        OREnvironment.set_objfunction!(st, 125.63);
        OREnvironment.set_constraint_consumption!(st, 3.0, 1);
        OREnvironment.set_constraint_consumption!(st, 4.0, 5);
        OREnvironment.update_status!(sol.status, st);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.is_optimal(sol) == false;
        @test OREnvironment.get_objfunction(sol) == 125.63;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 3.0;
        @test OREnvironment.get_constraint_consumption(sol, 5) == 4.0;
    end
end

@testset "Adding and removing solutions" begin
    value = 12.3;
    valueDummy = 0.0;
    @testset "FixLengthArray" begin
        sol  = constructorSolution();
        OREnvironment.add_solution!(sol, value,  3);
        OREnvironment.add_solution!(sol, 2value, 1);
        OREnvironment.add_solution!(sol, 3value, 2);
        @test OREnvironment.get_solution(sol, 3) == value; 
        @test OREnvironment.get_solution(sol, 1) == 2value; 
        @test OREnvironment.get_solution(sol, 2) == 3value; 
        OREnvironment.remove_solution!(sol, 3);
        @test OREnvironment.get_solution(sol, 3) == zero(Float64); 
        @test OREnvironment.get_solution(sol, 1) == 2value; 
        @test OREnvironment.get_solution(sol, 2) == 3value; 
        OREnvironment.remove_all_solutions!(sol);
        @test length(sol.sol) == 6;
        for v in sol.sol
            @test v == zero(Float64);
        end
    end
end

@testset "is first solution better" begin
    Tobj = Float64; Tconstraints = Float64; numConstraints = 5;
    status1 = OREnvironment.constructStatus(numConstraints, Tobj, Tconstraints);
    status2 = OREnvironment.constructStatus(numConstraints, Tobj, Tconstraints);
    Tvariables = Int; sizeArray = 6;
    s1 = OREnvironment.constructSolution(:FixLengthArray, (Tvariables, sizeArray, status1));
    s2 = OREnvironment.constructSolution(:FixLengthArray, (Tvariables, sizeArray, status2));
    OREnvironment.set_objfunction!(s1, 34);
    OREnvironment.set_objfunction!(s2, 3);

    @testset "feasibility not required" begin
        feasibility = false;
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;
    end

    @testset "feasibility required" begin
        feasibility = true;
        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3)
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == true;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == true;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_solution_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_solution_better(s2,s1,:min, feasibility) == false;
    end
end

@testset "copy_first_solution_to_second" begin
    s1 = constructorSolution();
    s2 = constructorSolution();
    p = constructorProblem();

    #OREnvironment.add_solution_and_update_status!(s1, 7.0, 1, p);
    #OREnvironment.add_solution_and_update_status!(s1, 7.4, 2, p);
    #OREnvironment.add_solution_and_update_status!(s1, 3.3, 3, p);
    OREnvironment.add_solution!(s1, 7.0, 1);
    OREnvironment.add_solution!(s1, 7.4, 2);
    OREnvironment.add_solution!(s1, 3.3, 3);
    OREnvironment.set_constraint_consumption!(s1, 26.66, 1); 
    OREnvironment.set_constraint_consumption!(s1, 36.96, 2); 
    OREnvironment.set_objfunction!(s1, 31.7);

    #OREnvironment.add_solution_and_update_status!(s2, 73.4, 4, p);
    #OREnvironment.add_solution_and_update_status!(s2, 8.0, 5, p);
    OREnvironment.add_solution!(s2, 73.4, 4);
    OREnvironment.add_solution!(s2, 8.0, 5);
    OREnvironment.set_constraint_consumption!(s2, 227.54, 1); 
    OREnvironment.set_constraint_consumption!(s2, 32.8, 2); 
    OREnvironment.set_objfunction!(s2, 333.6);

    @test OREnvironment.get_objfunction(s1) == 31.7;
    @test OREnvironment.get_objfunction(s2) == 333.6;
    @test OREnvironment.is_feasible(s1) == false;
    @test OREnvironment.is_feasible(s2) == false;
    @test OREnvironment.is_optimal(s1) == false;
    @test OREnvironment.is_optimal(s2) == false;
    @test OREnvironment.get_constraint_consumption(s1, 1) ≈ 26.66;
    @test OREnvironment.get_constraint_consumption(s1, 2) ≈ 36.96;
    @test OREnvironment.get_constraint_consumption(s2, 1) ≈ 227.54;
    @test OREnvironment.get_constraint_consumption(s2, 2) == 32.8;
  
    @test OREnvironment.get_solution(s1, 1) == 7.0; 
    @test OREnvironment.get_solution(s1, 2) == 7.4; 
    @test OREnvironment.get_solution(s1, 3) == 3.3; 
    @test OREnvironment.get_solution(s1, 4) == 0.0; 
    @test OREnvironment.get_solution(s1, 5) == 0.0; 
    @test OREnvironment.get_solution(s1, 6) == 0.0; 

    @test OREnvironment.get_solution(s2, 1) == 0.0; 
    @test OREnvironment.get_solution(s2, 2) == 0.0; 
    @test OREnvironment.get_solution(s2, 3) == 0.0; 
    @test OREnvironment.get_solution(s2, 4) == 73.4; 
    @test OREnvironment.get_solution(s2, 5) == 8.0; 
    @test OREnvironment.get_solution(s2, 6) == 0.0; 

    OREnvironment.set_feasible!(s1, true);
    OREnvironment.set_optimal!(s1, true);
    @test OREnvironment.is_feasible(s1) == true;
    @test OREnvironment.is_feasible(s2) == false;
    @test OREnvironment.is_optimal(s1) == true;
    @test OREnvironment.is_optimal(s2) == false;
    OREnvironment.copy_first_solution_to_second!(s1,s2);
    @test OREnvironment.get_solution(s1, 1) == 7.0; 
    @test OREnvironment.get_solution(s1, 2) == 7.4; 
    @test OREnvironment.get_solution(s1, 3) == 3.3; 
    @test OREnvironment.get_solution(s1, 4) == 0.0; 
    @test OREnvironment.get_solution(s1, 5) == 0.0; 
    @test OREnvironment.get_solution(s1, 6) == 0.0; 
    @test OREnvironment.get_solution(s2, 1) == 7.0; 
    @test OREnvironment.get_solution(s2, 2) == 7.4; 
    @test OREnvironment.get_solution(s2, 3) == 3.3; 
    @test OREnvironment.get_solution(s2, 4) == 0.0; 
    @test OREnvironment.get_solution(s2, 5) == 0.0; 
    @test OREnvironment.get_solution(s2, 6) == 0.0; 
  
    @test OREnvironment.get_objfunction(s1) == 31.7;
    @test OREnvironment.get_objfunction(s2) == 31.7;
    @test OREnvironment.is_feasible(s1) == true;
    @test OREnvironment.is_feasible(s2) == true;
    @test OREnvironment.is_optimal(s1) == true;
    @test OREnvironment.is_optimal(s2) == true;
    @test OREnvironment.get_constraint_consumption(s1, 1) ≈ 26.66;
    @test OREnvironment.get_constraint_consumption(s1, 2) ≈ 36.96;
    @test OREnvironment.get_constraint_consumption(s2, 1) ≈ 26.66;
    @test OREnvironment.get_constraint_consumption(s2, 2) ≈ 36.96;
end

#######################
# TESTS WHEN DEALING WITH CONSTRAINTS
#######################

@testset "update_constraint_consumption" begin
    sol  = constructorSolution();
    p = constructorProblem();

    @testset "feasible solution" begin
        sol.sol[1] = 1.0;
        sol.sol[2] = 10.0; # note that this doesn't appear in the constraints
        sol.sol[3] = 1.0;
        OREnvironment.update_constraint_consumption!(sol, p.constraints);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
    end

    @testset "infeasible solution" begin
        sol.sol[1] = 2.0;
        OREnvironment.update_constraint_consumption!(sol, p.constraints);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.8;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 10.8;
    end

    @testset "empty array of constraints" begin
        # the return is true because it would be the case of problem with no constraints.
        voidArray = Array{OREnvironment.DefaultConstraint, 1}();
        OREnvironment.update_constraint_consumption!(sol, voidArray);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.8;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 10.8;
    end
end

@testset "update_constraint_consumption_and_feasibility" begin
    sol  = constructorSolution();
    p = constructorProblem();

    @testset "feasible solution" begin
        sol.sol[1] = 1.0;
        sol.sol[2] = 10.0; # note that this doesn't appear in the constraints
        sol.sol[3] = 1.0;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
    end

    @testset "infeasible solution" begin
        sol.sol[1] = 2.0;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.8;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 10.8;
    end

    @testset "empty array of constraints" begin
        # the return is true because it would be the case of problem with no constraints.
        voidArray = Array{OREnvironment.DefaultConstraint, 1}();
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, voidArray);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.8;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 10.8;
    end
end

@testset "should_global_feasibility_be_checked" begin
  isSolutionFeasible  = true;
  isIncrementFeasible = true;
  @test OREnvironment.should_global_feasibility_be_checked(isSolutionFeasible, isIncrementFeasible) == false;
  
  isSolutionFeasible  = true;
  isIncrementFeasible = false;
  @test OREnvironment.should_global_feasibility_be_checked(isSolutionFeasible, isIncrementFeasible) == false;

  isSolutionFeasible  = false;
  isIncrementFeasible = false;
  @test OREnvironment.should_global_feasibility_be_checked(isSolutionFeasible, isIncrementFeasible) == false;
  
  isSolutionFeasible  = false;
  isIncrementFeasible = true;
  @test OREnvironment.should_global_feasibility_be_checked(isSolutionFeasible, isIncrementFeasible) == true;
end


@testset "update_constraint_consumption for increments" begin
    sol = constructorSolution();
    p = constructorProblem();

    sol.sol[1] = 1.0;
    sol.sol[3] = 1.0;
    OREnvironment.update_constraint_consumption!(sol, p.constraints);
    @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
    @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
  
    @testset "feasible solution" begin
        Δ = 0.2;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.32;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.58;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.98;
    end

    @testset "feasible solution negative sign" begin
        Δ = -0.2;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.32;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
    end

    @testset "infeasible solution" begin
        Δ = 1.5;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.15;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.15;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 13.65;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "empty Array" begin
        Δ = 1.5;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 2, Δ, p.variablesConstraints[2]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "empty constraints" begin
        Δ = 1.5;
        voidArray = Array{OREnvironment.DefaultConstraint, 1}();
        OREnvironment.update_constraint_consumption!(sol, voidArray, 2, Δ, p.variablesConstraints[2]);
    end

    @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
    @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;

    @testset "from infeasible to infeasible" begin
        Δ = -1.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "from infeasible to feasible" begin
        Δ = -3.0;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end

    @testset "from feasible to feasible" begin
        Δ = -1.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.4;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end

    @testset "from feasible to infeasible" begin
        Δ = 3.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 16.7;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end
end


@testset "update_constraint_consumption_and_feasibility for increments" begin
    sol = constructorSolution();
    p = constructorProblem();

    sol.sol[1] = 1.0;
    sol.sol[3] = 1.0;
    OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints);
    @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
    @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
  
    @testset "feasible solution" begin
        Δ = 0.2;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.32;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.58;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.98;
    end

    @testset "feasible solution negative sign" begin
        Δ = -0.2;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 8.32;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 6.12;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 5.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
    end

    @testset "infeasible solution" begin
        Δ = 1.5;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.15;
        @test OREnvironment.get_constraint_consumption(sol, 2) == 7.5;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.15;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 13.65;
        sol.sol[1] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 1, Δ, p.variablesConstraints[1]);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "empty Array" begin
        Δ = 1.5;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 2, Δ, p.variablesConstraints[2]);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "empty constraints" begin
        Δ = 1.5;
        voidArray = Array{OREnvironment.DefaultConstraint, 1}();
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, voidArray, 2, Δ, p.variablesConstraints[2]);
        @test OREnvironment.is_feasible(sol) == true;
    end

    OREnvironment.set_feasible!(sol, false);
    @test OREnvironment.get_constraint_consumption(sol, 1) == 13.6;
    @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;

    @testset "from infeasible to infeasible" begin
        Δ = -1.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 18.6;
    end

    @testset "from infeasible to feasible" begin
        Δ = -3.0;
        sol.sol[5] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 5, Δ, p.variablesConstraints[5]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 10.5;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end

    @testset "from feasible to feasible" begin
        Δ = -1.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == true;
        @test OREnvironment.get_constraint_consumption(sol, 1) == 7.4;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end

    @testset "from feasible to infeasible" begin
        Δ = 3.0;
        sol.sol[4] += Δ;
        OREnvironment.update_constraint_consumption_and_feasibility!(sol, p.constraints, 4, Δ, p.variablesConstraints[4]);
        @test OREnvironment.is_feasible(sol) == false;
        @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 16.7;
        @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 6.3;
    end
end

# @testset "Constraints with all negative consumption" begin
#     s = constructorSolution();
#     p = constructorProblemNegative();

#     OREnvironment.add_solution_and_update_status!(s, -2.0, 1, p);
#     lhs = OREnvironment.compute_lhs(p.constraints[1], s);
#     @test lhs == 4.6;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 1);
#     lhs = OREnvironment.compute_lhs(p.constraints[2], s);
#     @test lhs == 6.6;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 2);
#     @test OREnvironment.is_feasible(s) == false; 
#     @test OREnvironment.is_feasible(s, p.constraints) == false;

#     OREnvironment.add_solution_and_update_status!(s, -4.5, 2, p);
#     lhs = OREnvironment.compute_lhs(p.constraints[1], s);
#     @test lhs == 4.6;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 1);
#     lhs = OREnvironment.compute_lhs(p.constraints[2], s);
#     @test lhs == 6.6;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 2);
#     @test OREnvironment.is_feasible(s) == false; 
#     @test OREnvironment.is_feasible(s, p.constraints) == false;

#     OREnvironment.add_solution_and_update_status!(s, -1.5, 3, p);
#     lhs = OREnvironment.compute_lhs(p.constraints[1], s);
#     @test lhs == 9.4;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 1);
#     lhs = OREnvironment.compute_lhs(p.constraints[2], s);
#     @test lhs == 12.9;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 2);
#     @test OREnvironment.is_feasible(s) == false; 
#     @test OREnvironment.is_feasible(s, p.constraints) == false;

#     OREnvironment.add_solution_and_update_status!(s, -3.5, 3, p);
#     lhs = OREnvironment.compute_lhs(p.constraints[1], s);
#     @test lhs == 15.8;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 1);
#     lhs = OREnvironment.compute_lhs(p.constraints[2], s);
#     @test lhs == 21.3;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 2);
#     @test OREnvironment.is_feasible(s) == true; 
#     @test OREnvironment.is_feasible(s, p.constraints) == true;

#     OREnvironment.remove_all_solutions_and_update_status!(s, p);
#     lhs = OREnvironment.compute_lhs(p.constraints[1], s);
#     @test lhs == 0.0;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 1);
#     lhs = OREnvironment.compute_lhs(p.constraints[2], s);
#     @test lhs == 0.0;
#     @test lhs == OREnvironment.get_constraint_consumption(s, 2);
#     @test OREnvironment.is_feasible(s) == false; 
#     @test OREnvironment.is_feasible(s, p.constraints) == false;
    
# end

#######################
# TESTS WHEN DEALING WITH PROBLEMS
#######################
# @testset "Adding and removing solution with constraint update" begin
#     sol = constructorSolution();
#     p = constructorProblem();

#     @test OREnvironment.is_feasible(sol) == false;
#     @test OREnvironment.get_objfunction(sol) == 0.0;
#     @test OREnvironment.get_constraint_consumption(sol, 1) == 0.0;
#     @test OREnvironment.get_constraint_consumption(sol, 2) == 0.0;

#     @testset "Adding" begin
#         # from 0 to 2.5 => increase 2.5
#         OREnvironment.add_solution_and_update_status!(sol, 2.5, 1, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 2.5;
#         @test OREnvironment.get_constraint_consumption(sol, 1) == 5.75;
#         @test OREnvironment.get_constraint_consumption(sol, 2) == 8.25;
#         @test OREnvironment.get_solution(sol, 1) == 2.5;
#         for i in 2:6
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end
#         # from 2.5 to 3 => increase 0.5
#         OREnvironment.add_solution_and_update_status!(sol, 3.0, 1, p);
#         @test OREnvironment.is_feasible(sol) == false;
#         @test OREnvironment.get_objfunction(sol) == 3.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) == 6.9;
#         @test OREnvironment.get_constraint_consumption(sol, 2) == 9.9;
#         @test OREnvironment.get_solution(sol, 1) == 3.0;
#         for i in 2:6
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end

#         # from 3 to 1.5 => reduce of 1.5
#         OREnvironment.add_solution_and_update_status!(sol, 1.5, 1, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 1.5;
#         @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 3.45;
#         @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 4.95;
#         @test OREnvironment.get_solution(sol, 1) == 1.5;
#         for i in 2:6
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end

#         # from 0 to 1.75 in a variable that does not affect constraints 
#         OREnvironment.add_solution_and_update_status!(sol, 1.75, 2, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 5.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 3.45;
#         @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 4.95;
#         @test OREnvironment.get_solution(sol, 1) == 1.5;
#         @test OREnvironment.get_solution(sol, 2) == 1.75;
#         for i in 3:6
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end

#         # from 0 to 2.25 in variable 4 (affects only to the 1st constraint)
#         OREnvironment.add_solution_and_update_status!(sol, 2.25, 4, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 14.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 10.425;
#         @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 4.95;
#         @test OREnvironment.get_solution(sol, 1) == 1.5;
#         @test OREnvironment.get_solution(sol, 2) == 1.75;
#         @test OREnvironment.get_solution(sol, 4) == 2.25; 
#         for i in [3,5,6]
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end

#         # from 2.25 to 1 in variable 4
#         OREnvironment.add_solution_and_update_status!(sol, 1.0, 4, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 9.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 6.55;
#         @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 4.95;
#         @test OREnvironment.get_solution(sol, 1) == 1.5;
#         @test OREnvironment.get_solution(sol, 2) == 1.75;
#         @test OREnvironment.get_solution(sol, 4) == 1.0; 
#         for i in [3,5,6]
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end
#     end
#     @testset "Removing" begin
#         OREnvironment.remove_solution_and_update_status!(sol, 4, p);
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 5.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) ≈ 3.45;
#         @test OREnvironment.get_constraint_consumption(sol, 2) ≈ 4.95;
#         @test OREnvironment.get_solution(sol, 1) == 1.5;
#         @test OREnvironment.get_solution(sol, 2) == 1.75;
#         for i in 3:6
#             @test OREnvironment.get_solution(sol, i) == 0.0;
#         end
#     end
#     @testset "Removing all" begin
#         OREnvironment.set_feasible!(sol, false);
#         OREnvironment.remove_all_solutions_and_update_status!(sol, p); 
#         @test OREnvironment.is_feasible(sol) == true;
#         @test OREnvironment.get_objfunction(sol) == 0.0;
#         @test OREnvironment.get_constraint_consumption(sol, 1) == 0.0;
#         @test OREnvironment.get_constraint_consumption(sol, 2) == 0.0;
#     end
# end

