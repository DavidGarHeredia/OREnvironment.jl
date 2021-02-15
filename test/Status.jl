using OREnvironment
using Test

@testset "Building Status" begin
    typesObj = [Float16, Float32, Float64, Int];
    typesLHS = [Float16, Float32, Float64, Int];
    numConstraints = 5;
    for tObj in typesObj, tLHS in typesLHS
        status = OREnvironment.constructStatus(numConstraints, tObj, tLHS);
        # conditions after creation
        @test OREnvironment.is_feasible(status) == false;
        @test OREnvironment.is_optimal(status) == false;
        @test OREnvironment.get_objfunction(status) == zero(tObj);
        for i in 1:numConstraints
            @test OREnvironment.get_constraint_consumption(status, i) == zero(tLHS);
        end
        # conditions after modification
        OREnvironment.set_feasible!(status, true);
        OREnvironment.set_optimal!(status, true);
        OREnvironment.set_objfunction!(status, tObj(16));
        OREnvironment.set_constraint_consumption!(status, tLHS(15), 1);
        @test OREnvironment.is_feasible(status) == true;
        @test OREnvironment.is_optimal(status) == true;
        @test OREnvironment.get_objfunction(status) == tObj(16);
        @test OREnvironment.get_constraint_consumption(status, 1) == tLHS(15);
    end
end

@testset "is_first_status_better" begin
    numConstraints = 5;
    s1 = OREnvironment.constructStatus(numConstraints, Float64, Int);
    s2 = OREnvironment.constructStatus(numConstraints, Float64, Int);
    OREnvironment.set_objfunction!(s1, 34);
    OREnvironment.set_objfunction!(s2, 3);

    @testset "feasibility not required" begin
        feasibility = false;
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;
    end

    @testset "feasibility required" begin
        feasibility = true;
        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3)
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, false);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == true;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == true;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, false);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == true;

        OREnvironment.set_objfunction!(s1, 34);
        OREnvironment.set_objfunction!(s2, 3);
        OREnvironment.set_feasible!(s1, true);
        OREnvironment.set_feasible!(s2, true);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == true;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        OREnvironment.set_objfunction!(s2, 34);
        @test OREnvironment.is_first_status_better(s1,s2,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:max, feasibility) == false;
        @test OREnvironment.is_first_status_better(s1,s2,:min, feasibility) == false;
        @test OREnvironment.is_first_status_better(s2,s1,:min, feasibility) == false;
    end
end

@testset "Worst Value" begin
    @test OREnvironment.worst_value(:max, Float64) == -Inf;
    @test OREnvironment.worst_value(:min, Float64) == Inf;
    @test OREnvironment.worst_value(:max, Float32) == -Inf32;
    @test OREnvironment.worst_value(:min, Float32) == Inf32;
    @test OREnvironment.worst_value(:max, Float16) == -Inf16;
    @test OREnvironment.worst_value(:min, Float16) == Inf16;
end

@testset "update_status" begin
    numConstraints = 5;
    # first status
    s1 = OREnvironment.constructStatus(numConstraints, Float64, Float64);
    OREnvironment.set_objfunction!(s1, 34.0);
    OREnvironment.set_feasible!(s1, true);
    OREnvironment.set_optimal!(s1, true);
    OREnvironment.set_constraint_consumption!(s1, 1.2, 1);
    OREnvironment.set_constraint_consumption!(s1, 2.2, 2);
    OREnvironment.set_constraint_consumption!(s1, 3.2, 3);
    OREnvironment.set_constraint_consumption!(s1, 4.2, 4);
    OREnvironment.set_constraint_consumption!(s1, 5.2, 5);

    @test OREnvironment.is_feasible(s1) == true;
    @test OREnvironment.is_optimal(s1) == true;
    @test OREnvironment.get_objfunction(s1) == 34.0;
    @test OREnvironment.get_constraint_consumption(s1, 1) == 1.2;
    @test OREnvironment.get_constraint_consumption(s1, 2) == 2.2;
    @test OREnvironment.get_constraint_consumption(s1, 3) == 3.2;
    @test OREnvironment.get_constraint_consumption(s1, 4) == 4.2;
    @test OREnvironment.get_constraint_consumption(s1, 5) == 5.2;

    # second status
    s2 = OREnvironment.constructStatus(numConstraints, Float64, Float64);
    @test OREnvironment.is_feasible(s2) == false;
    @test OREnvironment.is_optimal(s2) == false;
    @test OREnvironment.get_objfunction(s2) == 0.0;
    for i in 1:numConstraints
        @test OREnvironment.get_constraint_consumption(s2, i) == 0.0;
    end

    # update
    OREnvironment.update_status!(s2, s1);

    @test OREnvironment.is_feasible(s1) == true;
    @test OREnvironment.is_optimal(s1) == true;
    @test OREnvironment.get_objfunction(s1) == 34.0;
    @test OREnvironment.get_constraint_consumption(s1, 1) == 1.2;
    @test OREnvironment.get_constraint_consumption(s1, 2) == 2.2;
    @test OREnvironment.get_constraint_consumption(s1, 3) == 3.2;
    @test OREnvironment.get_constraint_consumption(s1, 4) == 4.2;
    @test OREnvironment.get_constraint_consumption(s1, 5) == 5.2;

    @test OREnvironment.is_feasible(s2) == true;
    @test OREnvironment.is_optimal(s2) == true;
    @test OREnvironment.get_objfunction(s2) == 34.0;
    @test OREnvironment.get_constraint_consumption(s2, 1) == 1.2;
    @test OREnvironment.get_constraint_consumption(s2, 2) == 2.2;
    @test OREnvironment.get_constraint_consumption(s2, 3) == 3.2;
    @test OREnvironment.get_constraint_consumption(s2, 4) == 4.2;
    @test OREnvironment.get_constraint_consumption(s2, 5) == 5.2;
end