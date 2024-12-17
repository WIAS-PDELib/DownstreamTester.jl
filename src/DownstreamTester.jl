module DownstreamTester
using Pkg
using TestReports
using JSON
using Dates
using GitHub


function yesterday(date::Date)
    return date - Dates.Day(1)
end

function yesterday()
    return yesterday(today())
end

include("infos.jl")
include("xml.jl")
include("nightly.jl")
include("git.jl")


function main()
    packageinfo = JSON.parsefile("packages.json")
    for pack in packageinfo["packages"]
        if pack["nightly"]
            do_clone = false #switch to false after first clone for testing
            process_git(pack, do_clone)
            commithash = pack["githashes"][begin]
            nightly(pack)
        end
    end
    return nothing
end

export main
end # module DownstreamTester
