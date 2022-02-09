# frozen_string_literal: true

class AccountSearchResultMailerPreview < ActionMailer::Preview

  def search_result
    AccountSearchResultMailer.with(to_email: "example@example.com", search_term: "123", facility: Facility.first)
                             .search_result
  end

end
