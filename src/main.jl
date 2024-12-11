using Pkg
Pkg.add("TestReports")
Pkg.add("JSON")
Pkg.add("LightXML")
using TestReports
using JSON

include("nightly.jl")
include("git.jl")
include("xml.jl")

function main()
	packageinfo = JSON.parsefile("packages.json")
	for pack in packageinfo["packages"]
 		if pack["nightly"]
			process_git(pack)
			nightly(pack)
            failures = process_log(pack["nightlylog"])
            @show isempty(failures)
		end
        end		 
    return nothing
end


main()
