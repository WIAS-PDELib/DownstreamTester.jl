function nightly_testrun(pkgdict::Dict)
    Pkg.add(path=pkgdict["path"])
    name=pkgdict["name"]
    latest = pkgdict["githashes"][begin]
    logname = name*"_nightly_"*latest*"_v"*string(VERSION)*".xml"
    try
        TestReports.test(name;logfilename=logname)
    catch
    end
    merge!(pkgdict,Dict("nightlylog"=>logname))
    Pkg.rm(name) 
    return nothing
end


function nightly(pkgdict::Dict)
    nightly_testrun(pkgdict)
    return nothing
end

