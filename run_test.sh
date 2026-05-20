#!/bin/sh

# the following commands test that changes correctly propagate through
# symlinks and locking/unlocking files

################################################################################
# boring framework code
################################################################################

# The checks will all fail if there are uncommitted files in the repo.
# We therefore ensure there are no uncommitted files before performing the tests.
if ! [ -z "$(git status --porcelain)" ]; then
    echo 'ERROR: The git repo is not clean (i.e. you may have uncommitted files), but the test script requires a clean repo. You should either commit the files or delete them.'
    echo 'HINT: You can delete all uncommitted files with the `git clean -fd` command.'
    exit 1
fi

dotest() {
    mkdir -p .results
    cat > .results/"$1"
    diff .results/"$1" .expected/"$1"
}

# set default fac parameters if none given
[ $# -eq 0 ] && set -- --auto_commit=False

set -ex

################################################################################
# tests start here
################################################################################

fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint1

echo 'update' > build/b
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint2

fac "$@" --lock build/c
echo 'update again' > build/b
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint3

echo 'update third' > build/c
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint4

rm build/d
echo 'update fourth' > build/d
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint5

echo 'unlock' > build/a
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint6
# FIXME:
# the test above is "morally" broken;
# the build to build/f triggers a rebuild of build/b even though
# the intermediate dependency build/c is locked;
# preventing builds from traversing locks requires some heavy re-engineering

fac "$@" --unlock build/c
fac "$@" 'build/f'
files-to-prompt build | dotest checkpoint7

git clean -fd
