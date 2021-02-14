
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

function constructorProblemNegative()
    cost = collect(1.0:6.0);

    variables1 = [1, 3, 4, 6];
    variables2 = [1, 3, 5, 6];
    coefficients1 = -[2.3, 3.2, 3.1, 12.34];
    coefficients2 = coefficients1 .- 1.0; 
    constraint1 = OREnvironment.constructConstraint(15.0, :greaterOrEq, variables1, coefficients1); 
    constraint2 = OREnvironment.constructConstraint(9.0, :greaterOrEq, variables2, coefficients2); 
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

#######################
# TESTS 
#######################
@testset "Construct constraint and getters and setters" begin
    variables = [1, 10, 23, 56];
    coefficients = [2.3, 3.2, 3.1, 12.34];
    constraint = OREnvironment.constructConstraint(10.0, :greaterOrEq, variables, coefficients); 

    @test OREnvironment.get_rhs(constraint) == 10.0;
    @test OREnvironment.get_type(constraint) == :greaterOrEq;
    @test OREnvironment.get_coefficient(constraint, 1)  == 2.3;
    @test OREnvironment.get_coefficient(constraint, 56) == 12.34;
    @test OREnvironment.get_coefficient(constraint, 4)  == 0.0;
    @test OREnvironment.is_variable(constraint, 10) == true;
    @test OREnvironment.is_variable(constraint, 11) == false;

    OREnvironment.set_rhs!(constraint, 12.6);
    @test OREnvironment.get_rhs(constraint) == 12.6;
    OREnvironment.set_type!(constraint, :equal);
    @test OREnvironment.get_type(constraint) == :equal;
    OREnvironment.set_coefficient!(constraint, 23, 190.8);
    @test OREnvironment.get_coefficient(constraint, 23) == 190.8;
end

@testset "is_feasible" begin
    variables = [1, 10, 23, 56];
    coefficients = [2.3, 3.2, 3.1, 12.34];
    constraint = OREnvironment.constructConstraint(15.0, :lessOrEq, variables, coefficients); 

    @testset " <= constraints" begin
       lhs = 13.2;
       @test OREnvironment.is_feasible(constraint, lhs) == true;
       lhs = 15.0;
       @test OREnvironment.is_feasible(constraint, lhs) == true;
       lhs = 20.0;
       @test OREnvironment.is_feasible(constraint, lhs) == false;
    end
    @testset " => constraints" begin
       lhs = 13.2;
       OREnvironment.set_type!(constraint, :greaterOrEq);
       @test OREnvironment.is_feasible(constraint, lhs) == false;
       lhs = 15.0;
       @test OREnvironment.is_feasible(constraint, lhs) == true;
       lhs = 20.0;
       @test OREnvironment.is_feasible(constraint, lhs) == true;
    end
    @testset " == constraints" begin
       lhs = 13.2;
       OREnvironment.set_type!(constraint, :equal);
       @test OREnvironment.is_feasible(constraint, lhs) == false;
       lhs = 15.0;
       @test OREnvironment.is_feasible(constraint, lhs) == true;
       lhs = 20.0;
       @test OREnvironment.is_feasible(constraint, lhs) == false;
    end
end

@testset "is_increment_feasible and compute_lhs_increment" begin
    s = constructorSolution();
    p = constructorProblem();

    @testset "providing a variable that is not in the constraint" begin
        idx = 1;
        variable = 2;
        Δvariable = 12.0;
        lhs = OREnvironment.compute_lhs_increment(s, p.constraints[idx], idx, variable, Δvariable);
        feasible = OREnvironment.is_increment_feasible(s, p.constraints[idx], idx, variable, Δvariable);
        @test feasible == true;
        @test lhs == 0.0;
        idx = 2;
        lhs = OREnvironment.compute_lhs_increment(s, p.constraints[idx], idx, variable, Δvariable);
        feasible = OREnvironment.is_increment_feasible(s, p.constraints[idx], idx, variable, Δvariable);
        @test feasible == true;
        @test lhs == 0.0;
    end
    
    @testset "variable that is in both constraints" begin
        idx = 1;
        variable = 1;
        Δvariable = 5.0;
        lhs = OREnvironment.compute_lhs_increment(s, p.constraints[idx], idx, variable, Δvariable);
        feasible = OREnvironment.is_increment_feasible(s, p.constraints[idx], idx, variable, Δvariable);
        @test feasible == true;
        @test lhs == 11.5;
        idx = 2;
        lhs = OREnvironment.compute_lhs_increment(s, p.constraints[idx], idx, variable, Δvariable);
        feasible = OREnvironment.is_increment_feasible(s, p.constraints[idx], idx, variable, Δvariable);
        @test feasible == false;
        @test lhs == 16.5;
    end
end

@testset "is_increment_feasible" begin
    s = constructorSolution();
    p = constructorProblem();

    variable = 1;
    Δvariable = 1.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == true;
    Δvariable = 3.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == false;

    variable = 5;
    Δvariable = 1.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == true;
    Δvariable = 3.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == false;

    # case with no constraints 
    variable = 2;
    Δvariable = 10.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == true;
    Δvariable = 30.0;
    @test OREnvironment.is_increment_feasible(s, p.constraints, variable, Δvariable, p.variablesConstraints[variable]) == true;
end

@testset "compute_lhs and is_feasible" begin
    s = constructorSolution();
    p = constructorProblem();

    OREnvironment.add_solution_and_update_status!(s, 2.0, 1, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == true; 
    @test OREnvironment.is_feasible(s, p.constraints) == true;

    OREnvironment.add_solution_and_update_status!(s, 4.5, 2, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == true; 
    @test OREnvironment.is_feasible(s, p.constraints) == true;

    OREnvironment.add_solution_and_update_status!(s, 1.5, 3, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 9.4;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 12.9;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == false; 
    @test OREnvironment.is_feasible(s, p.constraints) == false;

    OREnvironment.remove_all_solutions_and_update_status!(s, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 0.0;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 0.0;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == true; 
    @test OREnvironment.is_feasible(s, p.constraints) == true;
end

@testset "get_relationship_variables_constraints" begin
    p = constructorProblem();
    variablesConstraints = OREnvironment.get_relationship_variables_constraints(p.constraints, 6);

    for i in 1:6
        if length(variablesConstraints[i]) == 0
            @test variablesConstraints[i] == Int[];
        else
            for j in 1:length(variablesConstraints[i])
                @test variablesConstraints[i][j] == p.variablesConstraints[i][j]; 
            end
        end
    end

    # when passing no constraints 
    dummy = Array{OREnvironment.DefaultConstraint,1}();
    variablesConstraints = OREnvironment.get_relationship_variables_constraints(dummy, 6);
    variablesConstraints == Array{Array{Int,1}, 1}();
end

@testset "Constraints with all negative consumption" begin
    s = constructorSolution();
    p = constructorProblemNegative();

    OREnvironment.add_solution_and_update_status!(s, -2.0, 1, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == false; 
    @test OREnvironment.is_feasible(s, p.constraints) == false;

    OREnvironment.add_solution_and_update_status!(s, -4.5, 2, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == false; 
    @test OREnvironment.is_feasible(s, p.constraints) == false;

    OREnvironment.add_solution_and_update_status!(s, -1.5, 3, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 9.4;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 12.9;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == false; 
    @test OREnvironment.is_feasible(s, p.constraints) == false;

    OREnvironment.add_solution_and_update_status!(s, -3.5, 3, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 15.8;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 21.3;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == true; 
    @test OREnvironment.is_feasible(s, p.constraints) == true;

    OREnvironment.remove_all_solutions_and_update_status!(s, p);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 0.0;
    @test lhs == OREnvironment.get_constraint_consumption(s, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 0.0;
    @test lhs == OREnvironment.get_constraint_consumption(s, 2);
    @test OREnvironment.is_feasible(s) == false; 
    @test OREnvironment.is_feasible(s, p.constraints) == false;
    
end