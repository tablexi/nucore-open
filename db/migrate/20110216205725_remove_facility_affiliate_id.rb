# frozen_string_literal: true

class RemoveFacilityAffiliateId < ActiveRecord::Migration

  def self.up
    remove_column(:facilities, :pers_affiliate_id)
  end

  def self.down
    add_column(:facilities, :pers_affiliate_id, :integer)
  end

end
