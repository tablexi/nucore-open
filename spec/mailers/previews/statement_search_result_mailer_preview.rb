# frozen_string_literal: true

class StatementSearchResultMailerPreview < ActionMailer::Preview

  def search_result
    params = { facility: Facility.first }
    StatementSearchResultMailer.with(to_email: "example@example.com", search_params: params).search_result
  end

end
