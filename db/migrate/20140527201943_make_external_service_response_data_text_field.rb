class MakeExternalServiceResponseDataTextField < ActiveRecord::Migration
  def up
    change_column :external_service_receivers, :response_data, :text
  end

  def down
    change_column :external_service_receivers, :response_data, :string
  end
end
