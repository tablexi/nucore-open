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
    [relation.order(:last_name, :first_name).limit(@limit), relation.count]
  end

  private

  def condition_sql
    <<-SQL
      (
          LOWER(first_name) LIKE ?
        OR
          LOWER(last_name) LIKE ?
        OR
          LOWER(username) LIKE ?
        OR
          LOWER(CONCAT(first_name, last_name)) LIKE ?
      )
    SQL
  end

  def query_conditions
    [condition_sql, @search_term, @search_term, @search_term, @search_term]
  end

  def relation
    @relation ||= User.where(query_conditions)
  end
end
