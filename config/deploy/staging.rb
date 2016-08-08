server "nucore.stage.tablexi.com", user: "nucore", roles: %(web app db)
set :deploy_to, "/home/nucore/nucore.stage.tablexi.com"
set :rails_env, "stage"
set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
