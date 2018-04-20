class AddSamlSessionIndexToUser < ActiveRecord::Migration
  def change
    add_column :users, :saml_session_index, :string
    add_index :users, :saml_session_index
  end
end
