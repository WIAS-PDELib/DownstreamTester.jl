struct NightlyDiff
    new::Set{FailureInfo}
    same::Set{FailureInfo}
    fixed::Set{FailureInfo}
end

function parse_previous_nightly(pkgdict::Dict)::NightlyInfo
    filename = pkgdict["name"] * "_nightly_" * string(yesterday()) * ".json"
    if !isfile(filename)
        return NightlyInfo("","",Set{FailureInfo}())
    end
    file = open(filename)
    info = parse(file, NightlyInfo)
    close(file)
    return info
end

function nightly_testrun(pkgdict::Dict)
    latest = pkgdict["githashes"][begin]
    ver = string(VERSION)
    name = pkgdict["name"]
    logname = name * "_nightly_" * latest * "_v" * ver * ".xml"
    Pkg.add(path = pkgdict["path"])
    try
        TestReports.test(name; logfilename = logname)
    catch
    end
    Pkg.rm(name)
    merge!(pkgdict, Dict("nightlylog" => logname))
    return nothing
end

function process_nightlylog(pkgdict::Dict)::NightlyInfo
    latest = pkgdict["githashes"][begin]
    failures = process_log(pkgdict["nightlylog"])
    return NightlyInfo(
        latest,
        string(VERSION),
        failures
    )
end

function diff_nightly(prev::NightlyInfo, curr::NightlyInfo)::NightlyDiff
    prevfails = Set(prev.failures)
    currfails = Set(curr.failures)
    same = intersect(prevfails, currfails)
    new = Set{FailureInfo}()
    fixed = Set{FailureInfo}()
    for prevfail in prevfails
        if prevfail ∉ currfails
            push!(fixed, prevfail)
        end
    end
    for currfail in currfails
        if currfail ∉ prevfails
            push!(new, currfail)
        end
    end
    return NightlyDiff(new, same, fixed)
end

function nightly_open_issue(pkgdict::Dict, new::Set{FailureInfo}, prev::NightlyInfo)
    latest = pkgdict["githashes"][1]
    title = "DownstreamTester nightly failure " * latest[1:6]

    commiturl = "https://github.com/" * pkgdict["source"] * "/commit/"
    compurl = "https://github.com/" * pkgdict["source"] * "/compare/"
    body = "[Start automated DownstreamTester.jl nightly report]\n\n"
    body *= "Dear all,\n\n"
    body *= "this is DownstreamTester.jl reporting a new nightly regression between\n\n"
    body *= "* new revision: [`" * latest[1:6] * "`](" * commiturl * latest * ") with Julia v" * string(VERSION) * "\n"
    if prev.commithash!="" && prev.nightlyversion!=""
        body *= "* old revision: [`" * prev.commithash[1:6] * "`](" * commiturl * prev.commithash * ") with Julia v" * prev.nightlyversion * "\n"
        if prev.commithash != latest
            body *= "* compare revisions: [`diff`](" * compurl * prev.commithash * "..." * latest * ")\n"
        end
    end
    body *= "\nFailing tests: \n\n"
    for failure in new
        body *= "* `" * failure.suite * "/`\n`" * failure.casename * "`\n"
        body *= "```\n"
        body *= failure.message
        body *= "```\n"
    end
    body *= "\n"
    body *= "Notes:\n\n"
    body *= "* This issue will automatically be closed once the failing tests"
    body *= " identified in this issue are passing again.\n\n"

    body *= "[End automated DownstreamTester.jl nightly report]"
    myauth = GitHub.authenticate(ENV["ISSUETOKEN"])
    issuecontent = Dict(
        "title" => title,
        "body" => body,
        "labels" => ["nightly"]
    )
    issue = GitHub.create_issue(
        pkgdict["reporting"]
        ;
        params = issuecontent,
        auth = myauth
    )
    @show issue
    return nothing
end

function nightly(pkgdict::Dict)
    prev = parse_previous_nightly(pkgdict)
    latest = pkgdict["githashes"][1]
    ver = string(VERSION)
    if prev.commithash == latest && prev.nightlyversion == ver
        @info "Test for " * pkgdict["name"] * "(" * latest * ") already run on Julia v" * ver
        info = prev
    else
        nightly_testrun(pkgdict)
        info = process_nightlylog(pkgdict)
        diff = diff_nightly(prev, info)
        @show diff
        #TODO: take action
        if !isempty(diff.new)
            @info "New failures since last run, opening issue."
            nightly_open_issue(pkgdict, diff.new, prev)
        end
        if !isempty(diff.fixed)
            @info "Fixed failures since last run, " *
                "check can  if issue can be closed."
        end
    end

    ## Print results to todays file
    jsonfile = open(pkgdict["name"] * "_nightly_" * string(today()) * ".json", "w")
    JSON.print(jsonfile, info, 2)
    close(jsonfile)

    return nothing
end
