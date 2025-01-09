# SPDX-License-Identifier: MIT

"""
    clonerepo(url, path)

Clone the newest (depth) commits of the default branch of 
the git repository at url into path

"""
function clonerepo(url, path, depth = 1)
    run(`git clone $url --depth=$depth $path`)
    return nothing
end

"""
    git_add_file(filename,path)

Add the file to the repository under path
"""
function git_add_file(filename, path)
    return run(Cmd(`git add $filename`; dir = path))
end

function git_commit(message, path)
    return run(Cmd(`git commit -m "$message"`; dir = path))
end

"""
    get_git_hashes!(path)

Get the commit hashes of the local branch in path
"""
function get_git_hashes!(path)
    # Only get hashes of all commits on HEAD
    gitlog = Cmd(`git log --format=format:"%H"`; dir = path)
    # Execute command and split into individual lines
    githashes = split(readchomp(gitlog), "\n")
    return githashes
end

"""
    process_git!(pkgconfig, do_clone::Bool)

This function gets information about the GitHub repo of a given package
It will start by cloning the repository into "../testdeps/<name>" 
(Unless do_clone is false, for local testing/development of DownstreamTester)
Then it will read the commit hashes of the local log and 
add information about the local path and hashes to the Dict of the package
"""
function process_git!(pkgconfig, do_clone::Bool = true)
    path = "../testdeps/" * pkgconfig["name"]
    if do_clone
        clonerepo(pkgconfig["url"] * ".git", path)
    end
    githashes = get_git_hashes!(path)
    # Note: githashes is truncated for now as more information is not yet needed
    merge!(pkgconfig, Dict("path" => path, "githashes" => githashes))
    return nothing
end
