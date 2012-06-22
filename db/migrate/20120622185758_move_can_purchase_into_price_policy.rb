class MoveCanPurchaseIntoPricePolicy < ActiveRecord::Migration
  def self.up
    add_column :price_policies, :can_purchase, :boolean, :after => :price_group_id, :default => false, :null => false
    PricePolicy.reset_column_information
    PriceGroupProduct.all.each do |pgp|
      price_policies = PricePolicy.find_all_by_price_group_id_and_product_id(pgp.price_group_id, pgp.product_id)
      if price_policies.any?
        price_policies.each do |pp|
          Rails.logger.debug "updating can_purchase #{pp.id}"
          # don't do validation
          pp.update_attribute(:can_purchase,  1)
        end
      else
        puts "Didn't find any policies for #{pgp.product} | #{pgp.price_group}"
        # skip bundles
        next if pgp.product.type == "Bundle"
        model_class = "#{pgp.product.type}PricePolicy".constantize
        pp = model_class.new(:product => pgp.product,
                             :price_group => pgp.price_group,
                             :can_purchase => true,
                             :start_date => Time.zone.now,
                             #TODO use SettingsHelper from fiscal_year branch
                             :expire_date => fiscal_year_end(Time.zone.now))
        pp.save!(:validate => false)
      end
    end
  end

  def self.down
    remove_column :price_policies, :can_purchase
    PricePolicy.where(:unit_cost => nil, :usage_rate => nil).each do |pp|
      pp.destroy
    end
  end

  def self.fiscal_year_end(date=nil)
    date ||= Time.zone.now
    (fiscal_year_beginning(date) + 1.year- 1.day).end_of_day
  end

  def self.fiscal_year_beginning(date=nil)
    date ||= Time.zone.now
    fiscal_year_starts = fiscal_year(date.year) 
    date.to_time >= fiscal_year_starts ? fiscal_year_starts : fiscal_year_starts - 1.year
  end
  def self.fiscal_year(year)
    Time.zone.parse("#{year}-09-01").beginning_of_day
  end
end
