#Anything related to processing the JUnit XML logs of TestReports
using LightXML

function process_testcase(testcase::XMLElement)::Set{FailureInfo}
    failures = Set{FailureInfo}()

    if name(testcase) != "testcase"
        return failures
    end
    if !has_children(testcase)
        return failures
    end
    for child in child_elements(testcase)
        if name(child) == "failure"
            suitename = attribute(testcase, "classname")
            casename = attribute(testcase, "name")
            failuremessage = content(child)
            failure = FailureInfo(
                suitename,
                casename,
                failuremessage
            )
            push!(failures, failure)
        end
    end
    return failures
end

function process_testsuite(testsuite::XMLElement)::Set{FailureInfo}
    failures = Set{FailureInfo}()

    if name(testsuite) != "testsuite"
        return failures
    end

    if attribute(testsuite, "failures") == "0"
        return failures
    end

    for case in child_elements(testsuite)
        newfailures = process_testcase(case)
        for entry ∈ newfailures
            push!(failures,entry)
        end
    end

    return failures
end

function process_log(logfile::String)::Set{FailureInfo}
    failures = Set{FailureInfo}()
    logxml = parse_file(logfile)
    logroot = root(logxml)
    #no processing needed if no failures were recorded
    if attribute(logroot, "failures") == "0" && attribute(logroot, "errors") == "0"
        return failures
    end
    # Find failing child node(s)
    for testsuite in child_elements(logroot)
        newfailures = process_testsuite(testsuite)
        for entry ∈ newfailures
            push!(failures, entry)
        end
    end

    return failures
end
