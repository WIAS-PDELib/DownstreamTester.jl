function clonerepo!(pkgdict)
	url = pkgdict["url"]
	path = "../testdeps/"*pkgdict["name"]
	run(`git clone $url --single-branch $path`)
    # Only get hashes of all commits on HEAD
    gitlog = Cmd(`git log --format=format:"%H"`;dir=path)
    # Exec and split into individual lines
    githashes = split(readchomp(gitlog),"\n")
	merge!(pkgdict,Dict("path"=>path,"githashes"=>githashes))
    return nothing
end

function process_git(pkgdict)
	clonerepo!(pkgdict)
    return nothing
end