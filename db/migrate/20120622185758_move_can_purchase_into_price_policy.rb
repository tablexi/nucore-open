class MoveCanPurchaseIntoPricePolicy < ActiveRecord::Migration
  def self.up
    add_column :price_policies, :can_purchase, :boolean, :after => :price_group_id, :default => false, :null => false
    
    PricePolicy.reset_column_information
    InstrumentPricePolicy.reset_column_information
    ServicePricePolicy.reset_column_information
    ItemPricePolicy.reset_column_information

    PriceGroupProduct.all.each do |pgp|
      price_policies = PricePolicy.find_all_by_price_group_id_and_product_id(pgp.price_group_id, pgp.product_id)
      if price_policies.any?
        price_policies.each do |pp|
          Rails.logger.debug "updating can_purchase #{pp.id}"
          # don't do validation
          pp.update_attribute(:can_purchase,  1)
        end
      else
        next if pgp.product.type == "Bundle" # skip bundles since they don't have their own price policies
        next if pgp.product.is_archived? # Ignore inactive products

        puts "Didn't find any policies for #{pgp.product.facility} ##{pgp.product.id} | #{pgp.product} | #{pgp.price_group}"
        model_class = "#{pgp.product.type}PricePolicy".constantize
        # create an expired policy
        pp = model_class.new(:product => pgp.product,
                             :price_group => pgp.price_group,
                             :can_purchase => true,
                             :start_date => 1.year.ago,
                             :expire_date => 1.year.ago)
        begin
          pp.save!(:validate => false)
        rescue Exception => e
          puts e.message
          puts e.backtrace
        end
      end
    end
  end

  def self.down
    remove_column :price_policies, :can_purchase
    PricePolicy.reset_column_information
    InstrumentPricePolicy.reset_column_information
    ServicePricePolicy.reset_column_information
    ItemPricePolicy.reset_column_information

    PricePolicy.where(:unit_cost => nil, :usage_rate => nil, :can_purchase => true).each do |pp|
      pp.destroy
    end
  end

end
