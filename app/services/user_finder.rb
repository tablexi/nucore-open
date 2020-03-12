# frozen_string_literal: true

class UserFinder

  include SearchHelper

  class_attribute :searchable_columns

  self.searchable_columns = [
    "first_name",
    "last_name",
    "username",
    "email",
  ]

  def self.search_with_count(search_term, limit = nil)
    if search_term.present?
      new(search_term, limit).result_with_count
    else
      [nil, nil]
    end
  end

  def self.search(search_term, limit = nil, table_alias: nil)
    if search_term.present?
      new(search_term, limit, table_alias: table_alias).result
    else
      nil
    end
  end

  def initialize(search_term, limit = nil, table_alias: nil)
    @search_term = generate_multipart_like_search_term(search_term)
    @limit = limit
    @table_alias = table_alias
  end

  def result_with_count
    [result, relation.count]
  end

  def result
    relation.order(:last_name, :first_name).limit(@limit)
  end

  private

  def relation
    conditions = searchable_columns.map { |column| arel_table[column].lower.matches(@search_term) }

    concat = Arel::Nodes::NamedFunction.new("CONCAT", [arel_table[:first_name].lower, arel_table[:last_name].lower])
    conditions << concat.matches(@search_term)

    @relation ||= User.where(conditions.inject(&:or))
  end

  def arel_table
    @table_alias ? Arel::Table.new(@table_alias) : User.arel_table
  end
end
