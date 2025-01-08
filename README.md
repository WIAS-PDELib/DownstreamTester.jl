# DownstreamTester

This package is aimed at simplifying and denoising nightly and downstream tests.
Instead of notifications for the same failing tests in scheduled CI runs
this package will open an issue on the respective repository and close it
once the failing tests pass again. 

**IMPORTANT** This package is still work in progress, so use at your own risk!

## Setup

### Logging branch
DownstreamTester.jl will store all information about previous runs and opened issues in a separate branch 
`downstreamtesterlogs`. 
For this to work the branch has to be created as an 'orphan' branch by calling
```
git checkout --orphan downstreamtesterlogs
git touch README.md # fill it with information if you want
git add README.md 
git commit -m "Initial commit on log branch"
git push -u origin downstreamtesterlogs
```
on a clone of the package repository.
This will start a branch with a new history (orphan) on the package repository.

### Personal Access Token for opening issues
To be able to open issues a personal 
access token will need to be generated 
[see](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token).
Afterwards you need to add it as a secret in your GitHub repository
and set the environment variable
`ISSUETOKEN` to contain that secret in the CI file.

### Configure DownstreamTester
By default DownstreamTester.jl 
expects the configuration to be in the file
`DownstreamTester.json` in the root folder 
of the repository.

### CI file
