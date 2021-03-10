# Branches and Forks

NUcore is usually deployed from a separate fork containing customized branding
and functionality. In order to move changes between the commits you'll need to
set up remote repositories on each side.

# Bringing changes from Open into your fork

_While in your fork's directory_

You should only need to do this once:

```
git remote add upstream git@github.com:tablexi/nucore-open.git
```

Create a new branch with the name `latest_from_open_MMDDYYYY` (reflecting the current date).

Whenever you want to bring the latest changes from open/master into your branch:

```
git fetch upstream
git merge upstream/master
```

Run `bin/merge_describer` which generates a helpful description you can copy/paste into your PR; it contains the commit messages and links to the merged branches since the last merge from open.

Push up your new branch, and paste the output from `bin/merge_describer` into the PR description.  For clarity it's best to sort commits into 3 groups: features, fixes, and tech tasks.

After adding the `upstream` remote, you can use the `bin/latest_from_open` script to create a new `latest_from_open_YYYYMMDD` branch.

When merging in changes from the open source repo, differences in `scehma.rb` and `Gemfile.lock` tend to be the trickiest to resolve.  Run `bundle` and `rails db:migrate` locally to ensure any conflicts have been resolved as expected.

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

# Deploy

General process:
1. Open a `latest_from_open_MMDDYYYY` branch
1. Merge the PR (not squash) once it has been approved and CI is green
1. For a production release, create a Github release:
  - Check out the commit you want to release and tag it: `git tag v2021-02-18`
  - Use `bin/merge_describer v2021-01-28` to list all commits since the previous release tag
  - Organize the output into features, fixes and tech tasks
  - Create a new release in Github using this list of commits for the description
  - Specify the new tag (`v2021-02-18`) for the release tag version, target, and release title
1. Deploy the new code using capistrano or helm/CircelCI (see below)
1. Run any relevant rake tasks
1. Go to staging and confirm new functionality is there

## Helm deploy steps

### To staging:

Merging to `master` will trigger a stage deployment.

### To production:

Approve the CircleCI job to trigger a production deployment.

## Capistrano deploy steps

### To staging:

From the root of your fork:

- `bundle exec cap [staging_name] deploy`

Find `staging_name` by the name of the `.rb` files in `config/deploy/[staging_name].rb`

### To production:

Prod releases need to be scheduled ahead of time with each school, and are typically done after hours.

From the root of your fork:

- `REVISION=[tag_to_release] bundle exec cap [prod_name] deploy`

The `tag_to_release` should be created in Github, for example `v2021-03-01`.
