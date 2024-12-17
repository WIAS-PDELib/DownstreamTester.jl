import DownstreamTester.FailureInfo

@testset "FailureInfo/equality" begin
    failinf = FailureInfo("a", "b", "c")
    @test FailureInfo("a", "b", "c") == failinf
    @test FailureInfo("d", "b", "c") != failinf
    @test FailureInfo("a", "d", "c") != failinf
    @test FailureInfo("a", "b", "d") != failinf
    @test FailureInfo("d", "d", "c") != failinf
    @test FailureInfo("d", "b", "d") != failinf
    @test FailureInfo("d", "d", "c") != failinf
end
