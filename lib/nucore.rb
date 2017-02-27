module NUCore

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

    # Oracle has problems with doing `DISTINCT *` on a table that contains
    # a CLOB (i.e. text) column.
    # See https://github.com/rsim/oracle-enhanced/issues/112
    module ClobSafeDistinct

      extend ActiveSupport::Concern

      module ClassMethods

        def clob_safe_distinct
          if NUCore::Database.oracle?
            # `select` instead of `pluck` results in a subquery rather than
            # two queries.
            where(id: distinct.select(:id))
          else
            distinct
          end
        end

      end

    end

    module WhereIdsIn

      extend ActiveSupport::Concern

      module ClassMethods

        def where_ids_in(ids)
          if NUCore::Database.oracle?
            return none if ids.blank?

            queries = ids.each_slice(999).flat_map do |id_slice|
              unscoped.where(id: id_slice).where_values
            end
            where(queries.reduce(:or))
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
