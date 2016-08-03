# config valid only for current version of Capistrano
lock "3.6.0"

set :application, "nucore"
set :repo_url, "git@github.com:tablexi/nucore-open.git"

# NOTE: We're managing our own binstubs in the repository
set :bundle_binstubs, nil
set :bundle_without, fetch(:bundle_without).concat(
  %w(oracle)
)

set :linked_files, fetch(:linked_files, []).concat(
  %w(config/database.yml config/settings.local.yml config/eye.yml.erb),
)
set :linked_dirs, fetch(:linked_dirs, []).concat(
  %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/files),
)

set :eye_config, "config/eye.yml.erb"
set :eye_env, -> { { rails_env: fetch(:rails_env) } }

# set :rollbar_token, ENV["ROLLBAR_ACCESS_TOKEN"]
# set :rollbar_env, Proc.new { fetch :rails_env }
# set :rollbar_role, Proc.new { :app }
