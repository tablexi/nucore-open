# frozen_string_literal: true

class AddContactEmailToProduct < ActiveRecord::Migration

  def self.up
    add_column :products, :contact_email, :string
  end

  def self.down
    remove_column :products, :contact_email
  end

end
