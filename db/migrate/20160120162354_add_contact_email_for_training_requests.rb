# frozen_string_literal: true

class AddContactEmailForTrainingRequests < ActiveRecord::Migration

  def change
    add_column :products, :training_request_contacts, :text
  end

end
