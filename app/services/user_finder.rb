# frozen_string_literal: true

class UserFinder

  include SearchHelper

  def self.search(search_term, limit)
    if search_term.present?
      new(search_term, limit).result
    else
      [nil, nil]
    end
  end

  def initialize(search_term, limit)
    @search_term = generate_multipart_like_search_term(search_term)
    @limit = limit
  end

  def result
    [users, relation.count]
  end

  private

  def condition_sql
    <<-SQL
      (
          LOWER(first_name) LIKE :search_term
        OR
          LOWER(last_name) LIKE :search_term
        OR
          LOWER(username) LIKE :search_term
        OR
          LOWER(CONCAT(first_name, last_name)) LIKE :search_term
        OR
          LOWER(email) LIKE :search_term
      )
    SQL
  end

  def relation
    @relation ||= User.where(condition_sql, search_term: @search_term)
  end

  def users
    relation.order(:last_name, :first_name).limit(@limit)
  end

end
