# DownstreamTester.jl

This package offers a toolkit for performing and tracking tests of 
downstream packages depending on the current package as well as tests against 
Julia nightly.

The **planned** nightly workflow is as follows


```mermaid
flowchart TD
    Start([Start up Julia nightly with call to `nightly`])
    readconfig(Read in config `DownstreamTester.json`)
    clone(Clone repo of package to test)
    Start --> readconfig --> clone
```
