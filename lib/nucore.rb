module NUCore

  # 'magic number'; is simply the most frequently used account by NU
  COMMON_ACCOUNT='75340'

  class PermissionDenied < SecurityError
  end

  class MixedFacilityCart < Exception
  end

  class NotPermittedWhileActingAs < Exception
  end

  class PurchaseException < Exception; end

  def self.portal
    return 'nucore'
  end

  module Database

    def self.oracle?
      @@is_oracle ||= ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
    end


    def self.boolean(value)
      # Oracle doesn't always properly handle boolean values correctly
      if self.oracle?
        value ? 1 : 0
      else
        value ? true : false
      end
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


    module RelationHelper
      #
      # If ActiveRecord might produce a query with a large IN clause (>= 1000)
      # then use this method. It prevents Oracle from barfing up this error:
      # OCIError: ORA-01795: maximum number of expressions in a list is 1000.
      # Essentially the method "slices" the query into sizeable chunks it knows
      # Oracle can handle.
      # [_relation_]
      #   An ActiveRecord::Relation
      # [_slice_size_]
      #   The number of results to fetch per query. Defaults to a size it knows
      #   Oracle can handle.
      # [_returns_]
      #   The results of the relation in an +Array+
      def query_in_slices(relation, slice_size = 999)
        # We could slice for all DBs but we might as well
        # do it all in 1 query if the DB (MySQL) can handle it
        return relation.all unless NUCore::Database.oracle?

        # If the limit has already been explicitly set, don't slice
        # Likely because the relation has already been paginated
        return relation if relation.limit_value

        offset = 0
        slice = []
        results = []

        begin
          slice = relation.limit(slice_size).offset(offset).all
          results += slice
          offset += slice_size
        end while slice.size == slice_size

        results
      end
    end


    module SortHelper
      def self.included(base)
        base.extend ClassMethods
      end
      module ClassMethods
        def order_by_desc_nulls_first(field)
          NUCore::Database.oracle? ? order("#{field} desc nulls first") : order("-#{field}")
        end
      end
    end

  end

end

