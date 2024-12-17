using Dates

import DownstreamTester.yesterday
@testset "yesterday()" begin
    @test yesterday(Date(2024, 12, 15)) == Date(2024, 12, 14)
    @test yesterday(Date(2024, 12, 1)) == Date(2024, 11, 30)
    @test yesterday(Date(2024, 1, 1)) == Date(2023, 12, 31)
end
