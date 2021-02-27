
using OREnvironment
using Test

#######################
# PRELIMINARIES FOR THE TESTS 
#######################
mutable struct MyProblem <: OREnvironment.Problem 
    costs::Array{Float64,1};
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
    status = OREnvironment.constructStatus(numConstraints);
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

@testset "add_constraint_index_to_variables" begin
    p = constructorProblem();
    variablesConstraints = [Int[] for i in 1:6];
    OREnvironment.add_constraint_index_to_variables!(p.constraints[1], 1, variablesConstraints);
    @test variablesConstraints[1] == [1];
    @test variablesConstraints[2] == Int[];
    @test variablesConstraints[3] == [1];
    @test variablesConstraints[4] == [1];
    @test variablesConstraints[5] == Int[];
    @test variablesConstraints[6] == [1];
    OREnvironment.add_constraint_index_to_variables!(p.constraints[2], 2, variablesConstraints);
    for i in 1:6
      @test variablesConstraints[i] == p.variablesConstraints[i];
    end
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
    @test variablesConstraints == Array{Array{Int,1}, 1}();
end

@testset "parse_and_set_constraint_sign" begin
  l1 = "12x1 + 13x2 + 5x3 <= 10";
  l2 = "1x2 + 23.2x14 + 5.3x6 >= 12";
  l3 = "2x5 + 3x7 + 5x19 = 15";
  lwithError1 = "1x2 + 23x4 + 5x6 => 12";
  lwithError2 = "1x2 + 23x4 + 5x6 == 12";
  c = OREnvironment.constructConstraint(0.0, :equal, Int[], Float64[]);

  sign = OREnvironment.parse_and_set_constraint_sign!(c, l1, 1);
  @test sign == "<=";
  @test OREnvironment.get_type(c) == :lessOrEq;
  sign = OREnvironment.parse_and_set_constraint_sign!(c, l2, 2);
  @test sign == ">=";
  @test OREnvironment.get_type(c) == :greaterOrEq;
  sign = OREnvironment.parse_and_set_constraint_sign!(c, l3, 3);
  @test sign == "=";
  @test OREnvironment.get_type(c) == :equal;
  @test_throws ErrorException OREnvironment.parse_and_set_constraint_sign!(c, lwithError1, 4);
  @test_throws ErrorException OREnvironment.parse_and_set_constraint_sign!(c, lwithError2, 5);
end

@testset "parse_constraint" begin
  l1 = "12x1 + 13x2 + 5x3 <= 10";
  l2 = "1x2 + 23.2x14 + 5.3x6 >= 12";
  l3 = "2x5 + 3x7 + 5x19 = 15";
  lwithError1 = "1x2 + 23x4 + 5x6 => 12";
  lwithError2 = "1x2 + 23x4 + 5x6 == 12";
  c = OREnvironment.constructConstraint(0.0, :equal, Int[], Float64[]);

  OREnvironment.parse_constraint!(c, l1, 1);
  @test OREnvironment.get_rhs(c) == 10;
  @test OREnvironment.get_type(c) == :lessOrEq;
  @test OREnvironment.is_variable(c, 1) == true;
  @test OREnvironment.is_variable(c, 2) == true;
  @test OREnvironment.is_variable(c, 3) == true;
  @test OREnvironment.get_coefficient(c, 1) == 12.0;
  @test OREnvironment.get_coefficient(c, 2) == 13.0;
  @test OREnvironment.get_coefficient(c, 3) == 5.0;

  OREnvironment.parse_constraint!(c, l2, 2);
  @test OREnvironment.get_rhs(c) == 12;
  @test OREnvironment.get_type(c) == :greaterOrEq;
  @test OREnvironment.is_variable(c, 2) == true;
  @test OREnvironment.is_variable(c, 14) == true;
  @test OREnvironment.is_variable(c, 6) == true;
  @test OREnvironment.get_coefficient(c, 2) == 1.0;
  @test OREnvironment.get_coefficient(c, 14) == 23.2;
  @test OREnvironment.get_coefficient(c, 6) == 5.3;

  OREnvironment.parse_constraint!(c, l3, 3);
  @test OREnvironment.get_rhs(c) == 15;
  @test OREnvironment.get_type(c) == :equal;
  @test OREnvironment.is_variable(c, 5) == true;
  @test OREnvironment.is_variable(c, 7) == true;
  @test OREnvironment.is_variable(c, 19) == true;
  @test OREnvironment.get_coefficient(c, 5) == 2.0;
  @test OREnvironment.get_coefficient(c, 7) == 3.0;
  @test OREnvironment.get_coefficient(c, 19) == 5.0;

  @test_throws ErrorException OREnvironment.parse_constraint!(c, lwithError1, 4);
  @test_throws ErrorException OREnvironment.parse_constraint!(c, lwithError2, 5);
end

@testset "read_constraints" begin
  testdir = dirname(@__FILE__);
  file = joinpath(testdir, "sampleConstraints.txt");
  constraints = OREnvironment.read_constraints(file);

  c = constraints[1];
  @test OREnvironment.get_rhs(c) == 9;
  @test OREnvironment.get_type(c) == :lessOrEq;
  @test OREnvironment.is_variable(c, 1) == true;
  @test OREnvironment.is_variable(c, 5) == true;
  @test OREnvironment.is_variable(c, 17) == true;
  @test OREnvironment.get_coefficient(c, 1) == 2.0;
  @test OREnvironment.get_coefficient(c, 5) == 3.0;
  @test OREnvironment.get_coefficient(c, 17) == 2.5;

  c = constraints[2];
  @test OREnvironment.get_rhs(c) == 12;
  @test OREnvironment.get_type(c) == :greaterOrEq;
  @test OREnvironment.is_variable(c, 24) == true;
  @test OREnvironment.is_variable(c, 122) == true;
  @test OREnvironment.is_variable(c, 3) == true;
  @test OREnvironment.is_variable(c, 1) == true;
  @test OREnvironment.get_coefficient(c, 24) == -3.0;
  @test OREnvironment.get_coefficient(c, 122) == 5.2;
  @test OREnvironment.get_coefficient(c, 3) == -2.1;
  @test OREnvironment.get_coefficient(c, 1) == 1;

  c = constraints[3];
  @test OREnvironment.get_rhs(c) == 4;
  @test OREnvironment.get_type(c) == :equal;
  @test OREnvironment.is_variable(c, 9) == true;
  @test OREnvironment.is_variable(c, 15) == true;
  @test OREnvironment.is_variable(c, 32) == true;
  @test OREnvironment.get_coefficient(c, 9) == 3.0;
  @test OREnvironment.get_coefficient(c, 15) == 23.0;
  @test OREnvironment.get_coefficient(c, 32) == -10.0;
end

@testset "is_increment_feasible and compute_lhs_after_increment" begin
    s = constructorSolution();
    p = constructorProblem();

    @testset "providing a variable that is not in the constraint" begin
        idx = 1;
        variable = 2;
        Δvariable = 12.0;
        currentLHS = OREnvironment.get_constraint_consumption(s, idx);
        lhs = OREnvironment.compute_lhs_after_increment(variable, Δvariable, currentLHS, p.constraints[idx]);
        feasible = OREnvironment.is_increment_feasible(variable, Δvariable, currentLHS, p.constraints[idx]);
        @test feasible == true;
        @test lhs == 0.0;
        idx = 2;
        currentLHS = OREnvironment.get_constraint_consumption(s, idx);
        lhs = OREnvironment.compute_lhs_after_increment(variable, Δvariable, currentLHS, p.constraints[idx]);
        feasible = OREnvironment.is_increment_feasible(variable, Δvariable, currentLHS, p.constraints[idx]);
        @test feasible == true;
        @test lhs == 0.0;
    end
    
    @testset "variable that is in both constraints" begin
        idx = 1;
        variable = 1;
        Δvariable = 5.0;
        currentLHS = OREnvironment.get_constraint_consumption(s, idx);
        lhs = OREnvironment.compute_lhs_after_increment(variable, Δvariable, currentLHS, p.constraints[idx]);
        feasible = OREnvironment.is_increment_feasible(variable, Δvariable, currentLHS, p.constraints[idx]);
        @test feasible == true;
        @test lhs == 11.5;
        idx = 2;
        currentLHS = OREnvironment.get_constraint_consumption(s, idx);
        lhs = OREnvironment.compute_lhs_after_increment(variable, Δvariable, currentLHS, p.constraints[idx]);
        feasible = OREnvironment.is_increment_feasible(variable, Δvariable, currentLHS, p.constraints[idx]);
        @test feasible == false;
        @test lhs == 16.5;
    end
end


#######################
# TESTS WHEN DEALING WITH SOLUTIONS
#######################
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

@testset "is_current_consumption_feasible" begin
    s = constructorSolution();
    p = constructorProblem();

    OREnvironment.set_constraint_consumption!(s, 7.0, 1);
    OREnvironment.set_constraint_consumption!(s, 7.0, 2);
    feasible = OREnvironment.is_current_consumption_feasible(s, p.constraints);
    @test feasible == true;

    OREnvironment.set_constraint_consumption!(s, 17.0, 1);
    feasible = OREnvironment.is_current_consumption_feasible(s, p.constraints);
    @test feasible == false;
    
    OREnvironment.set_constraint_consumption!(s, 7.0, 1);
    OREnvironment.set_constraint_consumption!(s, 17.0, 2);
    feasible = OREnvironment.is_current_consumption_feasible(s, p.constraints);
    @test feasible == false;

    OREnvironment.set_constraint_consumption!(s, 37.0, 1);
    feasible = OREnvironment.is_current_consumption_feasible(s, p.constraints);
    @test feasible == false;

    OREnvironment.set_constraint_consumption!(s, 6.0, 1);
    OREnvironment.set_constraint_consumption!(s, 5.0, 2);
    feasible = OREnvironment.is_current_consumption_feasible(s, p.constraints);
    @test feasible == true;
end

@testset "compute_lhs and is_feasible" begin
    s = constructorSolution();
    p = constructorProblem();

    OREnvironment.add_solution!(s, 2.0, 1);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test OREnvironment.is_feasible(s, p.constraints) == true;

    OREnvironment.add_solution!(s, 4.5, 2);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 4.6;
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 6.6;
    @test OREnvironment.is_feasible(s, p.constraints) == true;

    OREnvironment.add_solution!(s, 1.5, 3);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 9.4;
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 12.9;
    @test OREnvironment.is_feasible(s, p.constraints) == false;

    OREnvironment.remove_all_solutions!(s);
    lhs = OREnvironment.compute_lhs(p.constraints[1], s);
    @test lhs == 0.0;
    lhs = OREnvironment.compute_lhs(p.constraints[2], s);
    @test lhs == 0.0;
    @test OREnvironment.is_feasible(s, p.constraints) == true;
end
