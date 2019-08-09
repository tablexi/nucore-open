# frozen_string_literal: true

set :branch, ENV["CIRCLE_SHA1"] || ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"
set :rails_env, "stage"

server "tablexi-shared02.txihosting.com", user: "nucore", roles: %w(web app db)
set :deploy_to, "/home/nucore/nucore.stage.tablexi.com"
