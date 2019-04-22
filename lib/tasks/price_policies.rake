# frozen_string_literal: true

namespace :price_policies do

  desc "Duplicate the newest price policies for a facility's services to the current fiscal year"
  task :duplicate_to_current_fiscal_year, [:url_name] => :environment do |_t, args|
    facility = Facility.find_by!(url_name: args[:url_name])

    facility.services.not_archived.each do |service|
      service.price_policies.newest.each do |price_policy|
        next unless price_policy.expired? # Don't duplicate a current policy

        new_price_policy = price_policy.dup
        new_price_policy.start_date = SettingsHelper.fiscal_year_beginning
        new_price_policy.expire_date = SettingsHelper.fiscal_year_end
        new_price_policy.save!
      end
    end
  end

end
