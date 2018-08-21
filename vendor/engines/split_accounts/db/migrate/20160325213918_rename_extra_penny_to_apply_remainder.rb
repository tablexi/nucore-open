# frozen_string_literal: true

class RenameExtraPennyToApplyRemainder < ActiveRecord::Migration

  def change
    rename_column :splits, :extra_penny, :apply_remainder
  end

end
