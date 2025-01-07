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
    info = JSON.parsefile("DownstreamTester.json")
    repo = info["repo"]
    if !haskey(repo,"reporting")
        repo["reporting"]=repo["source"]
    end
    downstream = info["downstream"]

    # Starting nightly test for repo
    do_clone = false #switch to false after first clone for testing
    process_git(repo, do_clone)
    commithash = repo["githashes"][begin]
    nightly(repo)
    return nothing
end

export main
end # module DownstreamTester
