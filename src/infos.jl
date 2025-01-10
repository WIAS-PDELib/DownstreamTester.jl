# SPDX-License-Identifier: MIT

struct FailureInfo
    suite::String
    casename::String
    message::String
    location::String
end

"""
    Base.:(==)(left::FailureInfo, right::FailureInfo)

Comparison of two objects of type FailureInfo.
The failure is only the same if the suite, testcase and message match.
"""
function Base.:(==)(left::FailureInfo, right::FailureInfo)
    if left.suite != right.suite
        return false
    end
    if left.casename != right.casename
        return false
    end
    if left.message != right.message
        return false
    end
    #don't test location as it might change between revisions
    return true
end

struct DiffInfo
    new::Set{FailureInfo}
    same::Set{FailureInfo}
    fixed::Set{FailureInfo}
end


"""
    diff_failures(previous_failures::Set{FailureInfo}, current_failures::Set{FailureInfo})::DiffInfo

Compare the failures of a current testrun with the previous run.
The result with contain set of new failures, fixed failures 
and failures which still exist.
"""
function diff_failures(previous_failures::Set{FailureInfo}, current_failures::Set{FailureInfo})::DiffInfo
    same = intersect(previous_failures, current_failures)
    new = Set{FailureInfo}()
    fixed = Set{FailureInfo}()
    for failure in previous_failures
        if failure ∉ current_failures
            push!(fixed, failure)
        end
    end
    for failure in current_failures
        if failure ∉ previous_failures
            push!(new, failure)
        end
    end
    return DiffInfo(new, same, fixed)
end

struct NightlyInfo
    commithash::String
    nightlyversion::String
    failures::Set{FailureInfo}
end


"""
    parse(
        io::IO,
        NightlyInfo
    )::NightlyInfo

Parse the given JSON file into a NightlyInfo object
"""
function parse(
        io::IO,
        NightlyInfo
    )::NightlyInfo
    info = JSON.parse(io)
    nv = info["nightlyversion"]
    ch = info["commithash"]
    failures = Set{FailureInfo}()
    if (isempty(info["failures"]))
        return NightlyInfo(ch, nv, failures)
    end
    for entry in info["failures"]
        failure = FailureInfo(
            entry["suite"],
            entry["casename"],
            entry["message"],
            entry["location"]
        )
        push!(failures, failure)
    end
    return NightlyInfo(ch, nv, failures)
end

"""
    Base.:(==)(left::NightlyInfo, right::NightlyInfo)

Compare two NightlyInfo objects.
They are the same if the git revision and Julia version 
as well as the noticed failures are the same
"""
function Base.:(==)(left::NightlyInfo, right::NightlyInfo)
    if left.commithash != right.commithash
        return false
    end
    if left.nightlyversion != right.nightlyversion
        return false
    end
    if left.failures != right.failures
        return false
    end
    return true
end

"""
    parse_failures(content)

Parse the given collection of dicts into a Set{FailureInfo}
"""
function parse_failures(content)
    failures = Set{FailureInfo}()
    for failuredict in content
        failure = FailureInfo(
            failuredict["suite"],
            failuredict["casename"],
            failuredict["message"],
            failuredict["location"]
        )
        push!(failures, failure)
    end
    return failures
end
struct IssueInfo
    number::Int
    repo::String
    open::Set{FailureInfo}
    fixed::Set{FailureInfo}
end


"""
    parse_issues(issuefile::String)::Set{IssueInfo}

Parse the given JSON file into a Set{IssueInfo}
"""
function parse_issues(issuefile::String)::Set{IssueInfo}
    issues = Set{IssueInfo}()
    if !isfile(issuefile)
        return issues
    end
    content = JSON.parsefile(issuefile)
    for issuedict in content
        openfailures = parse_failures(issuedict["open"])
        fixedfailures = parse_failures(issuedict["fixed"])
        issue = IssueInfo(
            issuedict["number"],
            issuedict["repo"],
            openfailures,
            fixedfailures
        )
        push!(issues, issue)
    end
    return issues
end
