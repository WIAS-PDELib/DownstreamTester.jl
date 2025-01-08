# SPDX-License-Identifier: MIT

module DownstreamTester
using Pkg
using TestReports
using JSON
using Dates
using GitHub


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
