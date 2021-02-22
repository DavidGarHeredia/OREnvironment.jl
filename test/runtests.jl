using OREnvironment
using Test

const testdir = dirname(@__FILE__)

tests = [
    "Status"
    "Solution"
    "Constraints"
]

@testset "OREnvironment.jl" begin
    for t in tests
        @info "Testing $t"
        tp = joinpath(testdir, "$(t).jl")
        include(tp)
    end
end
