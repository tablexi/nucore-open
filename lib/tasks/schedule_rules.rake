# frozen_string_literal: true

namespace :schedule_rule do
  # This task is useful for switching a school over to PriceGroupDiscounts. If a
  # school is already using price group discounts on all its schedule rules, this
  # task will do nothing
  desc "Adds PriceGroupDiscounts for existing global price groups to every schedule rule"
  task add_price_group_discounts: :environment do |_t, _args|
    price_groups = PriceGroup.globals

    ScheduleRule.all.find_each do |schedule_rule|
      if schedule_rule.price_group_discounts.present?
        puts "Skipping schedule rule #{schedule_rule.id}, already has price_group_discounts"
      else
        price_groups.each_with_index do |price_group, _i|
          schedule_rule.price_group_discounts.create(
            price_group:,
            discount_percent: schedule_rule.discount_percent
          )
        end

        puts "Created price_group_discounts for #{schedule_rule.id}"
      end
    end
  end

  desc "Adds missing global price groups to existing schedule rules"
  task add_missing_price_group_discounts: :environment do |_t, _args|
    PriceGroup.globals.each(&:setup_schedule_rules)
  end
end
