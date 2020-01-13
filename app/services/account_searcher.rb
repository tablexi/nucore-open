# frozen_string_literal: true

class AccountSearcher

  MINIMUM_SEARCH_LENGTH = 3

  include SearchHelper

  def initialize(query, scope: Account.all)
    @query = query.to_s.strip
    @scope = scope
  end

  def valid?
    @query.to_s.length >= MINIMUM_SEARCH_LENGTH
  end

  def results
    owner_matches.or(
      account_number_matches
    ).order(:type, :account_number)
  end

  private

  def owner_matches
    where_clause = <<~SQL
      LOWER(users.first_name) LIKE :term
      OR LOWER(users.last_name) LIKE :term
      OR LOWER(users.username) LIKE :term
      OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
    SQL

    @scope.joins(account_users: :user).where(
      where_clause,
      term: like_term,
    ).merge(AccountUser.owners)
  end

  def account_number_matches
    # joins is needed to keep the structures identical for the OR
    @scope.joins(account_users: :user).where("LOWER(accounts.account_number) like ?", like_term)
  end

  # The @query, stripped of surrounding whitespace and wrapped in "%"
  def like_term
    generate_multipart_like_search_term(@query)
  end

end
