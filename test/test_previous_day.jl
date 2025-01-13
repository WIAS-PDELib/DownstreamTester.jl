using Dates

using DownstreamTester: previous_day
@testset "previous_day()" begin
    @test previous_day(Date(2024, 12, 15)) == Date(2024, 12, 14)
    @test previous_day(Date(2024, 12, 1)) == Date(2024, 11, 30)
    @test previous_day(Date(2024, 1, 1)) == Date(2023, 12, 31)
end
