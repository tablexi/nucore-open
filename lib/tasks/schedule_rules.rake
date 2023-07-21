# frozen_string_literal: true

namespace :schedule_rule do
  desc "Adds PriceGroupDiscounts for existing global price groups to every schedule rule"
  task add_price_group_discounts: :environment do |_t, _args|
    price_groups = PriceGroup.globals

    ScheduleRule.all.each do |schedule_rule|
      if schedule_rule.price_group_discounts.present?
        puts "Skipping schedule rule #{schedule_rule.id}, already has price_group_discounts"
      else
        price_groups.each_with_index do |price_group, _i|
          schedule_rule.price_group_discounts.create(
            price_group: price_group,
            discount_percent: schedule_rule.discount_percent
          )
        end

        puts "Created price_group_discounts for #{schedule_rule.id}"
      end
    end
  end

  desc "Adds PriceGroupDiscounts for new global price groups to every schedule rule"
  task :add_new_price_groups, [:discount] => :environment do |_t, args|
    price_groups = PriceGroup.globals
    discount_percent = args[:discount] || 0

    ScheduleRule.all.each do |schedule_rule|
      schedule_price_groups = schedule_rule.price_group_discounts.map(&:price_group)

      price_groups.each do |price_group|
        next if schedule_price_groups.include? price_group

        schedule_rule.price_group_discounts.create(
          price_group:,
          discount_percent:
        )

        puts "Created price_group_discount for #{price_group} and schedule rule #{schedule_rule.id}"
      end
    end
  end
end
