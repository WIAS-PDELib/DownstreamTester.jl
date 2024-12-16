module DownstreamTester
using Pkg
using TestReports
using JSON
using Dates

include("nightly.jl")
include("git.jl")
include("xml.jl")

function yesterday(date::Date)
    y = year(date)
    m = month(date)
    d = day(date)
    if d > 1
        return Date(y,m,d-1)
    end
    if m > 1
        return lastdayofmonth(Date(y,m-1,1))
    end
    return Date(y-1,12,31)
end
function yesterday()
    return yesterday(today())
end


function main()
	packageinfo = JSON.parsefile("packages.json")
	for pack in packageinfo["packages"]
 		if pack["nightly"]
            do_clone=true #switch to false after first clone for testing
			process_git(pack,do_clone)
            commithash = pack["githashes"][1]
			nightly(pack)
            # failures = process_log("ExtendableGrids_nightly_f814904b7afeadbe183b630314ae44d4186141f2_v1.11.2.xml")
            failures = process_log(pack["nightlylog"])
            
            info = Dict(
                "commit"=>commithash,
                "nightlyversion"=>string(VERSION),
                "failures"=>failures)
            jsonfile = open(pack["name"]*"_"*string(yesterday())*".json","w")
            JSON.print(jsonfile,info,2)
            close(jsonfile)
            # @show json(failures)
		end
        end		 
    return nothing
end

export main
end # module DownstreamTester
