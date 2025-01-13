# SPDX-License-Identifier: MIT

"""
    myauth()

Get GitHub authentication for environment variable "ISSUETOKEN"
"""
function myauth()
    return GitHub.authenticate(ENV["ISSUETOKEN"])
end

"""
    revision_link(url,revision)::String

Get Markdown link for given revision of code
"""
function revision_link(url, revision)::String
    return "[`" * revision[1:6] * "`](" * url * "/commit/" * revision * ")"
end


"""
    describe_testcase(testcase::FailureInfo)::String

Get Markdown flavoured description of `testcase`
"""
function describe_testcase(testcase::FailureInfo)::String
    description = "* `" * testcase.suite * "/`\n`"
    description *= testcase.casename * "`\n"
    description *= "```\n"
    description *= testcase.message
    description *= "```\n"
    return description
end


function describe_testsuites(failures::Set{FailureInfo})::String
    # Sort failures by testsuite
    d = Dict{String, Set{FailureInfo}}()
    for failure in failures
        suite = failure.suite
        if haskey(d, suite)
            push!(d[suite], failure)
        else
            merge!(d, Dict(suite => Set([failure])))
        end
    end
    description = ""
    for suite in eachindex(d)
        description *= "* Testsuite: `" * suite * "`\n"
        for case in d[suite]
            description *= "  * `" * case.casename * "`\n"
            description *= "    failed at `" * case.location * "`\n"
            description *= "    Evaluated: `" * case.message * "`\n\n"
        end
    end

    return description
end

"""
    mark_as_fixed!(issues::Set{IssueInfo},fixed::Set{FailureInfo},preamble::String)

Go through open DownstreamTester issues and comment on fixed failures.
If all failures of a given issue are fixed, close it.
"""
function mark_as_fixed!(issues::Set{IssueInfo}, fixed::Set{FailureInfo}, preamble::String)
    for issue in issues
        # New fixed need to be reported with a comment
        newfixes = Set{FailureInfo}()
        for fix in fixed
            # Is the fix a new one? If yes, move from open to fixed
            # and add to report.
            if fix in issue.open
                push!(newfixes, fix)
                push!(issue.fixed, fix)
                delete!(issue.open, fix)
            end
        end
        # Report on new fixes and close if possible
        if !isempty(newfixes)
            update_issue(issue, newfixes, preamble, isempty(issue.open))
        end
    end
    return
end


"""
    open_issue(repo::String, title::String, preamble::String, labels::Vector{String}, new::Set{FailureInfo})::IssueInfo

Open a new issue about failing tests in `repo`.
"""
function open_issue(repo::String, title::String, preamble::String, labels::Vector{String}, new::Set{FailureInfo})::IssueInfo
    # Construct issue message
    body = "[Start automated DownstreamTester.jl report]\n\n"
    body *= preamble

    body *= "\nFailing tests: \n\n"
    body *= describe_testsuites(new)
    body *= "\n"
    body *= "Notes:\n\n"
    body *= "* This issue will automatically be closed once the failing tests"
    body *= " identified in this issue are passing again.\n\n"

    body *= "[End automated DownstreamTester.jl report]"
    issuecontent = Dict(
        "title" => title,
        "body" => body,
        "labels" => labels
    )
    issue = GitHub.create_issue(
        repo
        ;
        params = issuecontent,
        auth = myauth()
    )
    return IssueInfo(issue.number, repo, new, Set{FailureInfo}())
end

"""
    update_issue(issueinfo::IssueInfo,fixes::Set{FailureInfo},preamble::String,allfixed::Bool=false)

Comment on given issue with the information about passing tests.
"""
function update_issue(issueinfo::IssueInfo, fixes::Set{FailureInfo}, preamble::String, allfixed::Bool = false)
    body = "[automated DownstreamTester.jl update]\n\n"
    body *= preamble
    body *= describe_testsuites(fixes)
    if allfixed
        body *= "\n All errors are now fixed, closing.\n"
    end
    GitHub.create_comment(
        issueinfo.repo,
        issueinfo.number,
        :issue
        ;
        auth = myauth(),
        params = Dict("body" => body)
    )
    return if allfixed
        close_issue(issueinfo)
    end
end

"""
    close_issue(issueinfo::IssueInfo)

Close the given issue on GitHub
"""
function close_issue(issueinfo::IssueInfo)
    return GitHub.edit_issue(
        issueinfo.repo,
        issueinfo.number;
        auth = myauth(),
        params = Dict("state" => "closed")
    )
end
