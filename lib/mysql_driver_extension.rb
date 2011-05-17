module MysqlDriverExtension
  # When the Oracle enhanced driver is used to generate schema.rb
  # it writes calls to the non-standard Rails methods defined here.
  # Below are equivalents for MySQL, needed because the MySQL driver
  # doesn't implement them and will die when trying to use Oracle's
  # version of schema.rb.
  #
  # Note that this class module will no longer be necessary once nucore
  # moves to Rails 3 because then we can use foreigner
  # (https://github.com/matthuhiggins/foreigner)

  def add_foreign_key(from_table, to_table, opts={})
    from_column=opts[:column]
    from_column=to_table.singularize + '_id' unless from_column

    constraint_name=opts[:name]
    constraint_name="fk_#{from_table}_#{from_column}" unless constraint_name
    
    execute <<-SQL
      ALTER TABLE #{from_table}
      ADD CONSTRAINT #{constraint_name}
      FOREIGN KEY (#{from_column})
      REFERENCES #{to_table}(id)
    SQL
  end

end