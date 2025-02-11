# SPDX-License-Identifier: MIT

"""
    parse_previous_nightly(pkgname::String)::NightlyInfo

Parse the JSON file of yesterdays log
"""
function parse_previous_nightly(logfile::String)::NightlyInfo
    if !isfile(logfile)
        return NightlyInfo("", "", Set{FailureInfo}())
    end
    file = open(logfile)
    info = parse(file, NightlyInfo)
    close(file)
    return info
end

"""
    nightly_testrun(name::String, path::String, logfile::String)

Perform the actual testrun on the cloned git repository in path
and write the results into the XML logfile
"""
function nightly_testrun(name::String, pkgpath::String, logpath::String, logname::String)
    Pkg.add(path = pkgpath)
    try
        TestReports.test(name; logfilepath = logpath, logfilename = logname)
    catch
    end
    Pkg.rm(name)
    return nothing
end


"""
    process_nightlylog(logfile::String, latest::String)::NightlyInfo

Parse a given nightly run XML log for test failures 
and return information about that run
"""
function process_nightlylog(logfile::String, latest::String, pkgname::String)::NightlyInfo
    failures = process_log(logfile, pkgname)
    return NightlyInfo(
        latest,
        string(VERSION),
        failures
    )
end


"""
    nightly(configfile::String="DownstreamTester.json")

Perform a nightly test on the Julia Package given in the config file.
This function is aimed to be run daily in a scheduled GitHub action 
to find and report on new test failures with the nightly version of Julia.
When called it will clone the HEAD revision of the package repository 
provided in the config and run the full testsuite on it. 
If new failing tests are found it will open an issue on the package repository.
If tests are passing it will report on the related issue and
close it if all reported tests therein pass.
"""
function nightly(configfile::String = "DownstreamTester.json"; do_clone = true)
    config = JSON.parsefile(configfile)
    nightlyconfig = config["repo"]
    process_git!(nightlyconfig, do_clone)
    latest = string(nightlyconfig["githashes"][1])
    ver = string(VERSION)
    name = nightlyconfig["name"]
    url = nightlyconfig["url"]

    @info "Starting DownstreamTester.jl for " * name * "(" * latest[1:6] * ") on Julia v" * ver

    logpath = "../testdeps/logs/"
    if !isdir(logpath)
        @error "Logfile folder not found! Please review installation instructions for the CI file."
    end
    previous_logfilename = logpath * name * "_nightly_" * string(yesterday()) * ".json"
    prev = parse_previous_nightly(previous_logfilename)
    if prev.commithash == latest && prev.nightlyversion == ver
        @info "Tests for this configuration already run yesterday, done."
        info = prev
    else
        issues = parse_issues(logpath * name * "_nightly_issues.json")
        # If reporting is not set, DownstreamTester will try to open an issue in
        # the source repo of the package to test
        if !haskey(nightlyconfig, "reporting")
            nightlyconfig["reporting"] = string(split(url, "github.com/")[end])
        end
        xmlfilename = name * "_nightly_" * latest * "_v" * ver * ".xml"
        nightly_testrun(name, nightlyconfig["path"], logpath, xmlfilename)
        if !isfile(logpath * xmlfilename)
            @info "XML file not found, tests did not run correctly."

            new = Set{FailureInfo}()
            failure = FailureInfo(
                "DownstreamTester",
                "nightly()",
                "XML file not found, check output of GitHub action",
                ".github/workflows/downstreamtester.yml"
            )
            if new in prev.failures
                @info "Problem already known."
            else
                @info "Opening issue."
                push!(new, failure)

                title = "DownstreamTester nightly not running " * latest[1:6]
                preamble = "Dear all,\n\n"
                preamble *= "this is DownstreamTester.jl reporting a failing *nightly* test run.\n\n"
                preamble *= "No XML output found, please check output of GitHub action for more details."

                issueinfo = open_issue(nightlyconfig["reporting"], title, preamble, ["nightly"], new)
                push!(issues, issueinfo)
                issuefilename = name * "_nightly_issues.json"
                issuefile = open(logpath * issuefilename, "w")
                JSON.print(issuefile, issues, 2)
                close(issuefile)
                git_add_file(issuefilename, logpath)
            end
        else

            info = process_nightlylog(logpath * xmlfilename, latest, name)
            diff = diff_failures(prev.failures, info.failures)

            if !isempty(diff.new)
                @info "New failures since last run, opening issue."

                title = "DownstreamTester nightly failure " * latest[1:6]
                preamble = "Dear all,\n\n"
                preamble *= "this is DownstreamTester.jl reporting a new *nightly* regression \n\n"
                preamble *= "* new revision: " * revision_link(url, latest) * " with Julia v" * ver * "\n"
                if prev.commithash != "" && prev.nightlyversion != ""
                    preamble *= "* old revision: " * revision_link(url, prev.commithash) * " with Julia v" * prev.nightlyversion * "\n"
                    if prev.commithash != latest
                        preamble *= "* compare revisions: [`diff`](" * url * "/compare/" * prev.commithash * "..." * latest * ")\n"
                    end
                end
                issueinfo = open_issue(nightlyconfig["reporting"], title, preamble, ["nightly"], diff.new)
                push!(issues, issueinfo)
            end

            if !isempty(diff.fixed)
                @info "Fixed failures since last run, " *
                    "check can  if issue can be closed."

                #Nightly specific start of comment text
                preamble = "The following tests are passing again "
                preamble *= "in revision " * revision_link(url, latest)
                preamble *= " with Julia v" * string(VERSION) * " :tada:\n\n"
                mark_as_fixed!(issues, diff.fixed, preamble)
            end

            #Overwrite issue file
            issuefilename = name * "_nightly_issues.json"
            issuefile = open(logpath * issuefilename, "w")
            JSON.print(issuefile, issues, 2)
            close(issuefile)
            git_add_file(issuefilename, logpath)
        end
    end

    ## Print results to todays file
    jsonfilename = name * "_nightly_" * string(today()) * ".json"
    jsonfile = open(logpath * jsonfilename, "w")
    JSON.print(jsonfile, info, 2)
    close(jsonfile)
    git_add_file(jsonfilename, logpath)
    git_commit("Add logs for " * string(today()), logpath)
    return nothing
end
