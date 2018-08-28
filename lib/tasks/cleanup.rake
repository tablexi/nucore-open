# frozen_string_literal: true

namespace :cleanup do
  namespace :accounts do
    desc "clean up accounts.expires_at column"
    task expires_at: :environment do
      Account.all.each do |a|
        AccountCleaner.clean_expires_at(a)
      end
    end
  end

  namespace :carts do
    desc "Cleans out abandoned carts (i.e. cart that have only an instrument order detail in them)"
    task destroy_abandoned: :environment do
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.level = Logger::INFO
      Cart.destroy_all_instrument_only_carts(5.days.ago)
    end
  end
end
