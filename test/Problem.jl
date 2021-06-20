using OREnvironment
using Test

@testset "VariableDomain" begin
  domain = OREnvironment.VariableDomain(1.0, 5.0)
  @test OREnvironment.get_lb(domain) == 1.0
  @test OREnvironment.get_ub(domain) == 5.0

  OREnvironment.set_lb!(domain, 2.0)
  OREnvironment.set_ub!(domain, 3.0)
  @test OREnvironment.get_lb(domain) == 2.0
  @test OREnvironment.get_ub(domain) == 3.0
end

@testset "building problem" begin 
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

  @test OREnvironment.get_number_of_constraints(p) == 2;
  @test OREnvironment.get_number_of_variables(p) == 6;

  @test OREnvironment.get_constraints(p) === constraints;
  for i in 1:length(cost)
    @test OREnvironment.get_cost(p, i) == cost[i];
    @test OREnvironment.get_lb_variable(p, i) == 0.0
    @test OREnvironment.get_ub_variable(p, i) == 5.0
  end
  for i in 1:length(variablesConstraints)
    @test OREnvironment.get_constraints_of_variable(p, i) == variablesConstraints[i];
  end
  for i in 1:length(cost)
    OREnvironment.set_cost!(p, i, 12.0*i); 
    OREnvironment.set_lb_variable!(p, i, 1.0) 
    OREnvironment.set_ub_variable!(p, i, 3.0) 
  end
  for i in 1:length(cost)
    @test OREnvironment.get_cost(p, i) == 12.0*i;
    @test OREnvironment.get_lb_variable(p, i) == 1.0
    @test OREnvironment.get_ub_variable(p, i) == 3.0
  end
  @test OREnvironment.get_obj_sense(p) == :max;
  OREnvironment.set_obj_sense!(p, :min);
  @test OREnvironment.get_obj_sense(p) == :min;

  @test OREnvironment.get_constraint(p, 1) === constraint1;
  @test OREnvironment.get_constraint(p, 1) == constraint1;
  @test OREnvironment.get_constraint(p, 2) === constraint2;
  @test OREnvironment.get_constraint(p, 2) == constraint2;

  @test OREnvironment.is_variable(OREnvironment.get_constraint(p,1), 1) == true;
  @test OREnvironment.is_variable(OREnvironment.get_constraint(p,1), 2) == false;
  @test OREnvironment.is_variable(OREnvironment.get_constraint(p,2), 4) == false;
  @test OREnvironment.is_variable(OREnvironment.get_constraint(p,2), 5) == true;
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,1)) == 15.0;
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,2)) == 9.0;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,2)) == :lessOrEq;
  @test OREnvironment.get_coefficient(OREnvironment.get_constraint(p,2), 5) == 4.1;
  @test OREnvironment.get_coefficient(OREnvironment.get_constraint(p,2), 4) == 0.0;
end

@testset "building problem as in practice" begin
  # read constraints one by one in a for loop and save them
  # obtain the variables constraints with the method
  # build the problem
  cost = rand(6);
  data_coefs = [rand(3), rand(2), rand(4)];
  data_vars  = [[1, 2, 3], [3, 6], [3, 4, 5, 6]];
  data_rhs = [12.3, 9.0, 33.0];
  data_symbol = [:lessOrEq, :equal, :greaterOrEq];
  # simulating the reading of constraints
  # check function read_constraints in ./test/Constraints.jl for actually
  # reading from a file!!!
  constraints = Array{OREnvironment.Constraint, 1}();
  for i in 1:3
    vars = data_vars[i]; # in practice we read from file
    coefs = data_coefs[i];
    rhs = data_rhs[i];
    symbol = data_symbol[i];
    push!(constraints, OREnvironment.constructConstraint(rhs, symbol, vars, coefs));
  end
  domain = [OREnvironment.VariableDomain(0.0, 5.0) for i in 1:6]
  p = OREnvironment.constructProblem(cost, constraints, :max, domain);

  # test that everything works
  variablesConstraints = OREnvironment.get_relationship_variables_constraints(constraints, 6);
  @test length(constraints) == 3;
  @test length(p.constraints) == 3;
  for i in 1:3
    @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,i)) == data_rhs[i];
    @test OREnvironment.get_type(OREnvironment.get_constraint(p,i)) == data_symbol[i];
    @test OREnvironment.get_constraint(p, i) == constraints[i];
    @test OREnvironment.get_constraint(p, i) === constraints[i];
  end
  for i in 1:6
    @test OREnvironment.get_cost(p,i) == cost[i];
    @test OREnvironment.get_constraints_of_variable(p, i) == variablesConstraints[i];
  end

  # simulating adding more constraints one by one
  constraint4 = OREnvironment.constructConstraint(3.9, :equal, [5, 6], [1.4, 11.0]);
  OREnvironment.add_constraint!(p, constraint4);
  @test length(p.constraints) == 4;
  @test length(constraints) == 4; # this is because p has a pointer to constraints!!!
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,4)) == 3.9;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,4)) == :equal;
  @test OREnvironment.get_constraint(p, 4) == constraint4;
  @test OREnvironment.get_constraint(p, 4) === constraint4;
  variablesConstraints = OREnvironment.get_relationship_variables_constraints(constraints, 6);
  for i in 1:6
    @test OREnvironment.get_constraints_of_variable(p, i) == variablesConstraints[i];
  end

  constraint5 = OREnvironment.constructConstraint(5.5, :greaterOrEq, [3, 6], [2.4, 11.0]);
  OREnvironment.add_constraint!(p, constraint5);
  @test length(p.constraints) == 5;
  @test length(constraints) == 5; # this is because p has a pointer to constraints!!!
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,5)) == 5.5;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,5)) == :greaterOrEq;
  @test OREnvironment.get_constraint(p, 5) == constraint5;
  @test OREnvironment.get_constraint(p, 5) === constraint5;
  variablesConstraints = OREnvironment.get_relationship_variables_constraints(constraints, 6);
  for i in 1:6
    @test OREnvironment.get_constraints_of_variable(p, i) == variablesConstraints[i];
  end
  
  # simulating adding more constraints as a vector
  constraint6 = OREnvironment.constructConstraint(6.9, :equal, [5, 6], [1.4, 11.0]);
  constraint7 = OREnvironment.constructConstraint(7.9, :lessOrEq, [5, 6], [1.4, 11.0]);
  newConstraints = [constraint6, constraint7];
  OREnvironment.add_constraint!(p, newConstraints);
  @test length(p.constraints) == 7;
  @test length(constraints) == 7; # this is because p has a pointer to constraints!!!
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,6)) == 6.9;
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,7)) == 7.9;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,6)) == :equal;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,7)) == :lessOrEq;
  @test OREnvironment.get_constraint(p, 6) == constraint6;
  @test OREnvironment.get_constraint(p, 6) === constraint6;
  @test OREnvironment.get_constraint(p, 7) == constraint7;
  @test OREnvironment.get_constraint(p, 7) === constraint7;
  variablesConstraints = OREnvironment.get_relationship_variables_constraints(constraints, 6);
  for i in 1:6
    @test OREnvironment.get_constraints_of_variable(p, i) == variablesConstraints[i];
  end
end

function build_problem()
  cost = collect(1.0:6.0);
  data_coefs = [[1.1, 1.2, 1.3], [2.1, 2.2], [3.1, 3.2, 3.3, 3.4]];
  data_vars  = [[1, 2, 3], [3, 6], [3, 4, 5, 6]];
  data_rhs = [12.3, 9.0, 33.0];
  data_symbol = [:lessOrEq, :equal, :greaterOrEq];
  # simulating the reading of constraints
  constraints = Array{OREnvironment.Constraint, 1}();
  for i in 1:3
    vars = data_vars[i]; # in practice we read from file
    coefs = data_coefs[i];
    rhs = data_rhs[i];
    symbol = data_symbol[i];
    push!(constraints, OREnvironment.constructConstraint(rhs, symbol, vars, coefs));
  end
  # variablesConstraints = OREnvironment.get_relationship_variables_constraints(constraints, 6);
  domain = [OREnvironment.VariableDomain(0.0, 5.0) for i in 1:6]
  p = OREnvironment.constructProblem(cost, constraints, :max, domain);
  return p;
end

@testset "scope of problem" begin
  # test that there is no issue with the scope of problem!
  p = build_problem();
  data_rhs = [12.3, 9.0, 33.0];
  data_symbol = [:lessOrEq, :equal, :greaterOrEq];
  @test length(p.constraints) == 3;
  for i in 1:3
    @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,i)) == data_rhs[i];
    @test OREnvironment.get_type(OREnvironment.get_constraint(p,i)) == data_symbol[i];
  end
  @test OREnvironment.get_coefficient(p.constraints[1], 1) == 1.1;
  @test OREnvironment.get_coefficient(p.constraints[1], 2) == 1.2;
  @test OREnvironment.get_coefficient(p.constraints[1], 3) == 1.3;
  @test OREnvironment.get_coefficient(p.constraints[1], 4) == 0.0;
  @test OREnvironment.get_coefficient(p.constraints[2], 3) == 2.1;
  @test OREnvironment.get_coefficient(p.constraints[2], 6) == 2.2;
  @test OREnvironment.get_coefficient(p.constraints[2], 5) == 0.0;
  @test OREnvironment.get_coefficient(p.constraints[3], 3) == 3.1;
  @test OREnvironment.get_coefficient(p.constraints[3], 4) == 3.2;
  @test OREnvironment.get_coefficient(p.constraints[3], 5) == 3.3;
  @test OREnvironment.get_coefficient(p.constraints[3], 6) == 3.4;
  for i in 1:6
    @test OREnvironment.get_cost(p,i) == i*1.0;
  end
  @test OREnvironment.get_constraints_of_variable(p, 1) == [1]; 
  @test OREnvironment.get_constraints_of_variable(p, 2) == [1]; 
  @test OREnvironment.get_constraints_of_variable(p, 3) == [1,2,3]; 
  @test OREnvironment.get_constraints_of_variable(p, 4) == [3]; 
  @test OREnvironment.get_constraints_of_variable(p, 5) == [3]; 
  @test OREnvironment.get_constraints_of_variable(p, 6) == [2,3]; 

  constraint4 = OREnvironment.constructConstraint(3.9, :equal, [5, 6], [1.4, 11.0]);
  OREnvironment.add_constraint!(p, constraint4);
  @test length(p.constraints) == 4;
  @test OREnvironment.get_rhs(OREnvironment.get_constraint(p,4)) == 3.9;
  @test OREnvironment.get_type(OREnvironment.get_constraint(p,4)) == :equal;
  @test OREnvironment.get_constraint(p, 4) == constraint4;
  @test OREnvironment.get_constraint(p, 4) === constraint4;
  @test OREnvironment.get_constraints_of_variable(p, 1) == [1]; 
  @test OREnvironment.get_constraints_of_variable(p, 2) == [1]; 
  @test OREnvironment.get_constraints_of_variable(p, 3) == [1,2,3]; 
  @test OREnvironment.get_constraints_of_variable(p, 4) == [3]; 
  @test OREnvironment.get_constraints_of_variable(p, 5) == [3, 4]; 
  @test OREnvironment.get_constraints_of_variable(p, 6) == [2,3,4]; 
end

@testset "gap function" begin 
  LB = 7.0;
  UB = 9.0;
  @test OREnvironment.gap(LB, UB, :min) == (UB-LB)/LB;
  @test OREnvironment.gap(LB, UB, :max) == (UB-LB)/UB;
end
