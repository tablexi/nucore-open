# frozen_string_literal: true

lock "~> 3.14.0"

set :application, "nucore"

set :bundle_without, "#{fetch(:bundle_without)} oracle"
set :eye_config, "config/eye.yml.erb"
set :eye_env, -> { { rails_env: fetch(:rails_env) } }
set :repo_url, "git@github.com:SquaredLabs/nucore-uconn.git"
set :rollbar_env, Proc.new { fetch :rails_env }
set :rollbar_role, Proc.new { :app }
set :rollbar_token, ENV["ROLLBAR_ACCESS_TOKEN"]

set :linked_files, fetch(:linked_files, []).concat(
  %w(config/database.yml config/secrets.yml config/eye.yml.erb config/settings.local.yml ),
)
set :linked_dirs, fetch(:linked_dirs, []).concat(
  %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/files),
)

set :chruby_ruby, "ruby-2.5.5"
