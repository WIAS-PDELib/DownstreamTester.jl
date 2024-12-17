import JSON

struct FailureInfo
    suite::String
    casename::String
    message::String
end

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
    return true
end

struct NightlyInfo
    commithash::String
    nightlyversion::String
    failures::Set{FailureInfo}
end

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
            entry["message"]
        )
        push!(failures, failure)
    end
    return NightlyInfo(ch, nv, failures)
end

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

function parse_previous_nightly(pkgdict::Dict)
    filename = pkgdict["name"] * "_nightly_" * string(yesterday()) * ".json"
    file = open(filename)
    info = parse(file, NightlyInfo)
    close(file)
    return info
end
