#Anything related to processing the JUnit XML logs of TestReports

using LightXML

struct FailureInfo
    suite::String
end

function process_log(logfile::String)::Vector{FailureInfo}
    failures = FailureInfo[]
    logxml = parse_file(logfile)
    logroot = root(logxml)
    #no processing needed if no failures were recorded
    if attribute(logroot,"failures")=="0" && attribute(logroot,"errors")=="0"
        return failures
    end


    return failures
end