function nightly_testrun(pkgdict::Dict)
    Pkg.add(path=pkgdict["path"])
    name=pkgdict["name"]
    latest = pkgdict["githashes"][begin]
    logname = name*"_nightly_"*latest*"_v"*string(VERSION)*".xml"
    TestReports.test(name;logfilename=logname)
    merge!(pkgdict,Dict("nightlylog"=>logname))
    Pkg.free(name) 
    return nothing
end


function nightly(pkgdict::Dict)
    nightly_testrun(pkgdict)
    return nothing
end

