# Deploying
This project uses [capistrano](https://github.com/capistrano/capistrano) to deploy to production and staging environments.

## Requirements
- You must have ruby 2.4.5 installed
- You must have SSH access to the `deploy` account in the target environment (production or staging)
    - If you do not have access, ask the team on slack and someone will assist you

### Don't have ruby 2.4.5?
If you don't have the required version of ruby, you can use [chruby](https://github.com/postmodern/chruby) and [ruby-install](https://github.com/postmodern/ruby-install):

1. [Install the ruby-install CLI tool](https://github.com/postmodern/ruby-install#install)
2. [Install the chruby CLI tool](https://github.com/postmodern/chruby#install)
3. [Configure chruby for your shell](https://github.com/postmodern/chruby#configuration)
3. Install ruby 2.4.5: `ruby-install ruby 2.4.5`


#### Activating the target ruby version
If you have [configured auto-switching](https://github.com/postmodern/chruby#auto-switching)
then `chruby` should automatically change to the correct ruby version when you
`cd` into the project directory. This is controlled by the `.ruby-version` file
in the project.

You may also manually activate ruby 2.4.5 by running:
```sh
chruby ruby-2.4.5
```

You can confirm that your ruby version is correct by running:
```sh
ruby -v
```
Your output should look something like:
```
ruby 2.4.5p335 (2018-10-18 revision 65137)
```

## Initial Setup
- `cd` to your project directory
- ensure the correct version of `ruby` is active
- ensure you are on the `master` branch
- run `bundle install`


## Performing Deploys
### Deploying to staging
Run:
```sh
bundle exec cap staging deploy
```

### Deploying to Production
Run:
```sh
bundle exec cap production deploy
```
