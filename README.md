# Weird File Tests

The following commands test that changes correctly propagate through
symlinks and locking/unlocking files.

## Ensure Sane

First we ensure that the git repo is clean.
(The command below will output a list of dirty files.)

```bash
$ git status --porcelain
```

```bash
$ export FAC_ARGS='--auto_commit=False'
```

## Tests Start Here

```bash
$ fac $FAC_ARGS 'build/f' 2>/dev/null
$ files-to-prompt build
build/a
---
test


---
build/b
---
test


---
build/c
---
test


---
build/d
---
test


---
build/e
---
test


---
build/f
---
test


---
```

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
