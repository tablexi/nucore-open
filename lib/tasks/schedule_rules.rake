# frozen_string_literal: true

namespace :schedule_rule do
  # This task is useful for switching a school over to PriceGroupDiscounts. If a
  # school is already using price group discounts on all its schedule rules, this
  # task will do nothing
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

  # Add missing global price groups to schedule rules.
  #
  # Run this whenever a new global price group is created. You can set a discount
  # percent for all schedule rules. The below example will set a 20% discount
  #
  # `rake schedule_rule:add_new_price_groups[20]`
  desc "Adds PriceGroupDiscounts for global price groups that have yet to be associated with schedule rules"
  task :add_new_price_groups, [:discount] => :environment do |_t, args|
    price_groups = PriceGroup.globals
    discount_percent = args[:discount] || 0

    ScheduleRule.all.each do |schedule_rule|
      schedule_price_groups = schedule_rule.price_group_discounts.map(&:price_group)

      price_groups.each do |price_group|
        if schedule_price_groups.include? price_group
          puts "price_group_discount for #{price_group} already exists for schedule rule #{schedule_rule.id}"
          next
        end

        schedule_rule.price_group_discounts.create(
          price_group:,
          discount_percent:
        )

        puts "Created price_group_discount for #{price_group} and schedule rule #{schedule_rule.id}"
      end
    end
  end
end
