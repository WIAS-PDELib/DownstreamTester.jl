#Anything related to processing the JUnit XML logs of TestReports

using LightXML

struct FailureInfo
    suite::String
    casename::String
    message::String
end
function process_testcase(testcase::XMLElement)::Vector{FailureInfo}
    failures = FailureInfo[]

    if name(testcase)!="testcase"
        return failures
    end
    if !has_children(testcase)
        return failures
    end
    for child ∈ child_elements(testcase)
        if name(child) == "failure"
            suitename = attribute(testcase,"classname")
            casename = attribute(testcase,"name")
            failuremessage = content(child)
            failure = FailureInfo(
                suitename,
                casename,
                failuremessage
            )
            push!(failures,failure)
        end
    end
    return failures
end

function process_testsuite(testsuite::XMLElement)::Vector{FailureInfo}
    failures = FailureInfo[]

    if name(testsuite)!="testsuite"
        return failures
    end

    if attribute(testsuite,"failures")=="0"
        return failures
    end

    for case ∈ child_elements(testsuite)
        append!(failures,process_testcase(case))
    end

    return failures
end

function process_log(logfile::String)::Vector{FailureInfo}
    failures = FailureInfo[]
    logxml = parse_file(logfile)
    logroot = root(logxml)
    #no processing needed if no failures were recorded
    if attribute(logroot,"failures")=="0" && attribute(logroot,"errors")=="0"
        return failures
    end
    # Find failing child node(s)
    for testsuite ∈ child_elements(logroot)
          append!(failures,process_testsuite(testsuite))
    end

    return failures
end