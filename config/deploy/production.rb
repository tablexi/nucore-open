server "prod.cider.core.uconn.edu", user: "deploy", roles: %w(web app db)
set :deploy_to, "/home/deploy/workspace/deploy"
set :rails_env, "production"
set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
