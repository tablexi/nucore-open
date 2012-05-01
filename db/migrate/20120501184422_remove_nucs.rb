class RemoveNucs < ActiveRecord::Migration
  def self.up
    if NUCore::Database.oracle?
      puts <<-WARN
        >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        You're running Oracle. Doing so usually requires the nucs engine. This migration removes the nucs tables!
        If you really want to run this migration on Oracle you need to rollback to the previous migration version
        and remove the condition that caused this message.
        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      WARN
    else
      [ :nucs_accounts, :nucs_chart_field1s, :nucs_departments, :nucs_funds,
        :nucs_gl066s, :nucs_grants_budget_trees, :nucs_programs, :nucs_project_activities ].each do |table|
        drop_table table
      end
    end
  end

  def self.down
    puts ">>> This migration should be reversed by running `rake db:migrate` from inside the nucs engine! <<<"
  end
end
