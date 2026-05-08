#!/bin/sh

set -ex
alias fac='python3 -m fac --auto_commit=False'

# The idea of this test script is that we will run a series of build commands
# and check to see if the files that have been created match the files that should have been created.
# This function performs the actual check to see if the files match and will be called by the test cases below.
dotest() {
    # NOTE:
    # The testing procedure is inspired by the standard for postgresql test scripts.
    # This function should be called with a single parameter,
    # which is the name of the test case.
    # The ground truth files that should exist will be stored in the `.expected` folder,
    # and the files that actually exist after the run of these tests will be stored in the `.results` folder.
    # The `.results` folder should never be added to the git repo.
    # We use hidden folder names (prefixed with the dot) so that they do not get tracked with the ls -R command.
    mkdir -p .results
    #files-to-prompt --ignore fac.yaml --ignore *.sh . > .results/"$1" 
    # files-to-prompt outputs the contents of all files (recursively) to stdout;
    # we cannot use the command above, however, because files-to-prompt is non-deterministic in its output order;
    # we need to combine find + sort to get a deterministic ordering of the files
    files-to-prompt $(find . -type f -not -path "*/.*" -type f -not -name "*.sh" -not -name "*.yaml" | sort) > .results/"$1"
    diff .results/"$1" .expected/"$1"
}

# This function cleans all files in the repo except those in the results folder.
# It is useful for writing tests that build from scratch.
clean_repo() {
    git clean -fd -e .results/
}

# The checks will all fail if there are uncommitted files in the repo.
# We therefore ensure there are no uncommitted files before performing the tests.
if ! [ -z "$(git status --porcelain)" ]; then
    echo 'ERROR: The git repo is not clean (i.e. you may have uncommitted files), but the test script requires a clean repo. You should either commit the files or delete them.'
    echo 'HINT: You can delete all uncommitted files with the `git clean -fd` command.'
    exit 1
fi

# the following commands test that changes correctly propagate through
# symlinks and locking/unlocking files
# tests that changes to 
clean_repo
fac 'test/f'
dotest checkpoint1

echo 'update' > test/b
fac 'test/f'
dotest checkpoint2

fac --lock test/c
echo 'update again' > test/b
fac 'test/f'
dotest checkpoint3

echo 'update third' > test/c
fac 'test/f'
dotest checkpoint4

rm test/d
echo 'update fourth' > test/d
fac 'test/f'
dotest checkpoint5

fac --unlock test/c
echo 'unlock' > test/a
fac 'test/f'
dotest checkpoint6
