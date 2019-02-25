# frozen_string_literal: true

class AddIssueReportRecipientsToProduct < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :issue_report_recipients, :text
  end
end
