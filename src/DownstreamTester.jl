# SPDX-License-Identifier: MIT

"""
    DownstreamTester
"""
module DownstreamTester
using Pkg: Pkg
using TestReports: TestReports
using JSON: JSON
using Dates: Dates, Date, today
using GitHub: GitHub, labels, repo


"""
    previous_day(date::Date)

Get the date of the day before the given date.
"""
function previous_day(date::Date)
    return date - Dates.Day(1)
end

"""
    yesterday()

Get the date of yesterday
"""
function yesterday()
    return previous_day(today())
end

include("infos.jl")
include("xml.jl")
include("git.jl")
include("github.jl")
include("nightly.jl")

export nightly
end # module DownstreamTester
