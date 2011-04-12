class AlterPricePoliciesPopulatePriceGroupsProducts < ActiveRecord::Migration
  def self.up
    PricePolicy.all.each do |policy|
      attrs={ :price_group => policy.price_group }

      if policy.is_a? ItemPricePolicy
        attrs.merge!(:product => policy.item)
      elsif policy.is_a? ServicePricePolicy
        attrs.merge!(:product => policy.service)
      elsif policy.is_a? InstrumentPricePolicy
        attrs.merge!(:product => policy.instrument)
        attrs.merge!(:reservation_window => policy.reservation_window)
      end

      PriceGroupProduct.create!(attrs)
    end

    remove_column(:price_policies, :reservation_window)
  end


  def self.down
    add_column(:price_policies, :reservation_window, :integer)
    PricePolicy.reset_column_information

    PriceGroupProduct.all.each do |pgp|
      next unless pgp.product.is_a? Instrument
      policy=PricePolicy.find_by_instrument_id_and_price_group_id(pgp.product.id, pgp.price_group.id)
      policy.reservation_window=pgp.reservation_window
      policy.save!
      pgp.destroy
    end
  end
end
