server "ec2-54-145-34-29.compute-1.amazonaws.com", user: "ubuntu", roles: %w(web app db)
set :deploy_to, "/home/ubuntu/workspace/deploy"
set :rails_env, "production"
set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
