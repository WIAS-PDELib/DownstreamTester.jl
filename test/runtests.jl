using DownstreamTester
using Test
using Aqua
using ExplicitImports

println("Testing...")

include("test_previous_day.jl")
#include("test_infos.jl")

@testset "ExplicitImports" begin
    @test ExplicitImports.check_no_implicit_imports(DownstreamTester) === nothing
    @test ExplicitImports.check_no_stale_explicit_imports(DownstreamTester) === nothing
end

@testset "Aqua" begin
    Aqua.test_all(DownstreamTester)

end

@testset "UndocumentedNames" begin
    @test isempty(Docs.undocumented_names(DownstreamTester))
end
