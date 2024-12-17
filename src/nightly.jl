struct NightlyDiff
    new::Set{FailureInfo}
    same::Set{FailureInfo}
    fixed::Set{FailureInfo}
end

function nightly_testrun(pkgdict::Dict)
    latest = pkgdict["githashes"][begin]
    ver = string(VERSION) 
    name = pkgdict["name"]
    logname = name * "_nightly_" * latest * "_v" * ver * ".xml"
    Pkg.add(path=pkgdict["path"])
    try
        TestReports.test(name;logfilename=logname)
    catch
    end
    merge!(pkgdict, Dict("nightlylog" => logname))
    Pkg.rm(name)
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

function diff_nightly(prev::NightlyInfo,curr::NightlyInfo)::NightlyDiff
    prevfails = Set(prev.failures)
    currfails = Set(curr.failures)
    same = intersect(prevfails,currfails)
    new = Set{FailureInfo}()
    fixed = Set{FailureInfo}()
    for prevfail ∈ prevfails
        if prevfail ∉ currfails
            push!(fixed,prevfail)
        end
    end
    for currfail ∈ currfails
        if currfail ∉ prevfails
            push!(new,currfail)
        end
    end
    return NightlyDiff(new,same,fixed)
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
        diff = diff_nightly(prev,info)
        @show diff
        #TODO: take action 
        if !isempty(diff.new)
            @info "New failures since last run, opening issue."
        end
        if !isempty(diff.fixed)
            @info "Fixed failures since last run, "*
                  "check can  if issue can be closed."
        end
    end
    
    ## Print results to todays file
    jsonfile = open(pkgdict["name"] * "_nightly_" * string(today()) * ".json", "w")
    JSON.print(jsonfile, info, 2)
    close(jsonfile)




    return nothing
end
