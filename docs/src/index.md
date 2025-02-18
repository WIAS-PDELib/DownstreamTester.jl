# DownstreamTester.jl

This package offers a toolkit for performing and tracking tests of 
downstream packages depending on the current package as well as tests against 
Julia nightly.


Currently, only the nightly workflow is implemented.

The nightly workflow is as follows

```mermaid
flowchart TD
    Start(("
    call to 
    nightly(configfile;
    kwargs)   
    "))
    readconfig[read in config JSON file]
    clone["
    clone package repo
    get HEAD commit hash
    "]
    test[run tests and note failures]
    diff[compare failures with logs]
    newfail{New failures?}
    openissue[Open new issue on GitHub]
    logissue[Log information about issue]
    newfix{New fixes?}
    issueinfo[("   
    issue info:
    - number                           
    - repo
    - failures(Set)
    - fixed(Set)            
    ")]
    failureinfo[("
    failure info:
    - test suite
    - test case
    - error message
    - location
    ")]
    writelog["
    Write failures to logfile
    together with:
    package commit hash
    Julia nightly version
    "]
    markfixed["
    Search resp. issue 
    mark failure(s) as fixed
    "]
    issuefixed{"
    for each issue:
    are all failures fixed?"
    }
    saveinfo[Update issue log]
    closeissue[Close issue on GitHub]
    done((done))
    Start --> readconfig --> clone --> test --> diff -->newfail
    newfail --> |Yes| openissue --> logissue --> newfix
    logissue--> issueinfo
    test --> failureinfo --> writelog
    newfail --> |No| newfix
    newfix --> |Yes| markfixed --> issuefixed
    newfix --> |No| saveinfo --> done
    issuefixed --> |Yes| closeissue --> issuefixed
    issuefixed --> |All checked| saveinfo
    
```
