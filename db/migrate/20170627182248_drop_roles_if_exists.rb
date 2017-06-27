class DropRolesIfExists < ActiveRecord::Migration
  def change
    if table_exists?(:roles)
      drop_table(:roles) do |t|
        t.string "name", limit: 255
      end
    end
  end
end
