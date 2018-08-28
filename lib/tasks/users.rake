# frozen_string_literal: true

namespace :users do
  desc "Retreives users that have been active in the past year as CSV"
  task list_active: :environment do
    finder = Users::ActiveUserFinder.new
    puts finder.active_users_csv(1.year.ago)
  end
end
