module NUCore

  # 'magic number'; is simply the most frequently used account by NU
  COMMON_ACCOUNT='75340'

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
        #
        # This method should be used anytime you need to reference a date column in a
        # SQL query and the column values should be treated as a date, not a datetime.
        # It will keep your code DB agnostic.
        # [_date_column_name_]
        #   The name of the column whose values should be treated as dates
        # [_sql_fragment_]
        #   Any SQL that makes sense to come after +date_column_name+ in the query.
        #   Simply a convenience; the fragment is just concatenated to the returned value.
        def dateize(date_column_name, sql_fragment=nil)
          col_sql=NUCore::Database.oracle? ? "TRUNC(#{date_column_name})" : "DATE(#{date_column_name})"
          sql_fragment ? col_sql + sql_fragment : col_sql
        end
      end
    end

  end

end

