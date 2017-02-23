# Branches and Forks

NUcore is usually deployed from a separate fork containing customized branding
and functionality. In order to move changes between the commits you'll need to
set up remote repositories on each side.

# Bringing changes from Open into your fork

_While in your fork's directory_

You should only need to do these once:

```
git remote add upstream git@github.com:tablexi/nucore-open.git
```

Create a new branch with the name `latest_from_open_YYYYMMDD` (reflecting the current date).

Whenever you want to bring the latest changes from open/master into your branch:

```
git fetch upstream
git merge upstream/master
```

Push up your new branch, and run `bin/merge_describer` which generates a helpful description you can copy/paste into your PR; it contains the commit messages and links to the merged branches since the last merge from open.

# Bringing changes on your fork into Open

_While in `nucore-open`_

For example, with the NU fork:

`git remote add nu git@github.com:tablexi/nucore-nu.git`

The best way to bring in the changes from NU is by cherry-picking the individual
commits. For this reason, it's best to develop on open to start with, or to squash
the commits in your branch so you only need to bring one commit.

```
git fetch nu
git cherry-pick XXXXX
```
