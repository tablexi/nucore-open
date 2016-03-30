module NUCore

  # 'magic number'; is simply the most frequently used account by NU
  COMMON_ACCOUNT = "75340".freeze

  class PermissionDenied < SecurityError
  end

  class MixedFacilityCart < StandardError
  end

  class NotPermittedWhileActingAs < StandardError
  end

  class PurchaseException < StandardError; end

  def self.portal
    "nucore"
  end

  module Database

    def self.oracle?
      @@is_oracle ||= ActiveRecord::Base.connection.adapter_name == "OracleEnhanced"
    end

    def self.mysql?
      @@is_mysql ||= ActiveRecord::Base.connection.adapter_name == "Mysql2"
    end

    def self.boolean(value)
      # Oracle doesn't always properly handle boolean values correctly
      if oracle?
        value ? 1 : 0
      else
        value ? true : false
      end
    end

    module WhereIdsIn

      extend ActiveSupport::Concern

      module ClassMethods

        def where_ids_in(ids)
          if NUCore::Database.oracle?
            queries = ids.each_slice(999).flat_map do |id_slice|
              unscoped.where(id: id_slice).where_clauses
            end
            where(queries.join(" OR "))
          else
            where(id: ids)
          end
        end

      end

    end

    module DateHelper

      def self.included(base)
        base.extend ClassMethods
      end

      # Two digit years gte this value will be treated as 19XX
      Y2K_CUTOFF = 86

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
        def dateize(date_column_name, sql_fragment = nil)
          col_sql = NUCore::Database.oracle? ? "TRUNC(#{date_column_name})" : "DATE(#{date_column_name})"
          sql_fragment ? col_sql + sql_fragment : col_sql
        end

        def parse_2_digit_year_date(date_string)
          day, month, year = date_string.match(/\A(\d{1,2})\-?([A-Z]{3})\-?(\d\d)\z/).captures
          year = year.to_i >= Y2K_CUTOFF ? "19#{year}" : "20#{year}"
          Time.zone.parse("#{day} #{month} #{year}")
        end

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

    module CaseSensitivityHelper

      def insensitive_where(relation, column, value)
        relation.where("UPPER(#{column}) = UPPER(?)", value)
      end

    end

  end

end
