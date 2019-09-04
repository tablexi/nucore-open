# frozen_string_literal: true

class StatementSearchResultMailerPreview < ActionMailer::Preview

  def search_result
    params = { facility: Facility.first }
    StatementSearchResultMailer.search_result("example@example.com", params)
  end

end
