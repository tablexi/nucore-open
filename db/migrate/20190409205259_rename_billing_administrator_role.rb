# frozen_string_literal: true

class RenameBillingAdministratorRole < ActiveRecord::Migration[5.0]
  def up
  	UserRole.where(role: "Billing Administrator").each do |user|
  		user.role = "Global Billing Administrator"
  		user.save!
  	end
  end

  def down
  	UserRole.where(role: "Global Billing Administrator").each do |user|
  		user.role = "Billing Administrator"
  		user.save!
  	end
  end
end
