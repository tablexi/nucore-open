# frozen_string_literal: true

namespace :users do
  task downcase_usernames: :environment do
    User.update_all("username = lower(username)")
  end
end
