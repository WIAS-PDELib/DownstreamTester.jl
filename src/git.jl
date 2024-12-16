function clonerepo!(pkgdict,do_clone=true)
	url = pkgdict["url"]
	path = "../testdeps/"*pkgdict["name"]
    if do_clone
	    run(`git clone $url --single-branch $path`)
    end
    # Only get hashes of all commits on HEAD
    gitlog = Cmd(`git log --format=format:"%H"`;dir=path)
    # Exec and split into individual lines
    githashes = split(readchomp(gitlog),"\n")
	merge!(pkgdict,Dict("path"=>path,"githashes"=>githashes))
    return nothing
end

function process_git(pkgdict,do_clone::Bool)
	clonerepo!(pkgdict,do_clone)
    return nothing
end