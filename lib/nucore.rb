module NUCore

  class PermissionDenied < SecurityError
  end

  class MixedFacilityCart < Exception
  end

  class NotPermittedWhileActingAs < Exception
  end

  def self.portal
    return 'nucore'
  end

  def self.app_name
    return 'NU Core'
  end

  module Database

    def self.oracle?
      @@is_oracle ||= ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
    end


    module DateHelper
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def dateize(date_column_name, sql_fragment=nil)
          col_sql=NUCore::Database.oracle? ? "TRUNC(#{date_column_name})" : date_column_name
          sql_fragment ? col_sql + sql_fragment : col_sql
        end
      end
    end


    module MySQL
      module DriverExtension
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
    end

  end

end

