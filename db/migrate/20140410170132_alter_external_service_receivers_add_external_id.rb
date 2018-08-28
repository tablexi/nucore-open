# frozen_string_literal: true

class AlterExternalServiceReceiversAddExternalId < ActiveRecord::Migration

  def change
    add_column :external_service_receivers, :external_id, :string
  end

end
