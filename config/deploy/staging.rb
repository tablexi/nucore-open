# frozen_string_literal: true

server "test.cider.core.uconn.edu", user: "deploy", roles: %w(web app db)
set :deploy_to, "/home/deploy/workspace/deploy"
set :rails_env, "stage"
set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
