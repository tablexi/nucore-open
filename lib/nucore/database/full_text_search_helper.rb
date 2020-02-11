# frozen_string_literal: true

module Nucore

  module Database

    module FullTextSearchHelper

      extend ActiveSupport::Concern

      included do
        if NUCore::Database.oracle?
          has_context_index
          extend OracleFullTextSearchHelper
        else
          extend MySqlFullTextSearchHelper
        end
      end

      module OracleFullTextSearchHelper

        def full_text(fields, query)
          formatted_query = query.split.join(",")
          # If we leave the label out `:label`, we end up with duplicate labels which Oracle doesn't like.
          # If we don't handle the `order` ourselves, then AR's `or` complains about incompatible `ORDER BY`s.
          array = Array(fields)
          relation = array.map.with_index { |field, i| contains("#{arel_table.name}.#{field}", formatted_query, label: i).unscope(:order) }.inject(&:or)

          array.length.times.inject(relation) do |relation, label|
            relation.order(Arel.sql("SCORE(#{label}) DESC"))
          end
        end

      end

      module MySqlFullTextSearchHelper

        def full_text(fields, query)
          full_fields = Array(fields).map { |field| "#{arel_table.name}.#{field}" }.join(", ")
          where("MATCH(#{full_fields}) AGAINST (?)", query)
        end

      end

    end

  end

end
